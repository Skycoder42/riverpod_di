# Upstream bug: `ConstantReaderX.toExpression()` cannot handle collection constants

**Package:** `dart_test_tools` (reproduced against 7.3.0)
**File:** `lib/src/code_gen/expressions.dart`
**Found via:** `riverpod_di_generator`, reading a `@Riverpod(dependencies: [...])` annotation.

## Symptom

Any annotation field whose constant value is a `List`, `Set` or `Map` of
non-literal elements crashes the generator with an unhandled `UnsupportedError`
and a raw stack trace instead of an `InvalidGenerationSource`:

```
Unsupported operation: Not a supported literal type: int Function(Ref) (custom).
  #0  literal (package:code_builder/src/specs/expression/literal.dart:24)
  #1  ExpressionEmitter._acceptLiteral (package:code_builder/src/specs/expression.dart:587)
  #2  ExpressionEmitter.visitLiteralListExpression.<anonymous closure>.<anonymous closure>
  ...
```

Minimal input:

```dart
@riverpod
int custom(Ref ref) => 1;

// dependencies: [custom] is what breaks
@RiverDi(Riverpod(keepAlive: true, dependencies: [custom]))
class WithDeps(Leaf leaf);
```

## Cause

```dart
extension ConstantReaderX on ConstantReader {
  Expression toExpression() {
    if (isLiteral) {
      return literal(literalValue);   // <-- here
    }
    ...
  }
}
```

`source_gen`'s `ConstantReader.isLiteral` returns `true` for collections
(`reader.dart:187` — `isBool || isString || isInt || isDouble || isList ||
isMap || isSymbol || isSet || isNull`), but `literalValue` for a collection is
`objectValue.toListValue()` / `toSetValue()` / `toMapValue()`, which return
`List<DartObject>` / `Set<DartObject>` / `Map<DartObject, DartObject>` — the
**elements stay wrapped as `DartObject`**.

`code_builder`'s `literal()` then builds a `LiteralListExpression` whose values
are raw `DartObject`s. At emit time `_acceptLiteral` passes anything that is not
a `Spec` to `literal()` again, which throws for a `DartObject`.

`source_gen` even documents this on `literalValue`:

> Throws `FormatException` if a valid literal value cannot be returned. This is
> the case if the constant is not a literal **or if the literal value is
> represented at least partially with `DartObject` instances.**

…but the implementation does not actually throw, so the failure surfaces much
later inside the emitter.

The same defect applies to `RevivableX._mapObject`, which routes every revived
argument back through `ConstantReaderX.toExpression()`.

## Suggested fix

Recurse into collections instead of handing raw `DartObject`s to `literal()`:

```dart
Expression toExpression() {
  if (objectValue.toListValue() case final list?) {
    return literalList(list.map((e) => ConstantReader(e).toExpression()));
  }
  if (objectValue.toSetValue() case final set?) {
    return literalSet(set.map((e) => ConstantReader(e).toExpression()));
  }
  if (objectValue.toMapValue() case final map?) {
    return literalMap({
      for (final MapEntry(:key, :value) in map.entries)
        ConstantReader(key).toExpression():
            ConstantReader(value).toExpression(),
    });
  }
  if (isLiteral) {
    return literal(literalValue);
  }
  // ... existing function-value / revive handling
}
```

Note the ordering: the collection checks must come **before** the `isLiteral`
branch, and `_acceptLiteral` already passes `Spec` values straight through, so
nested `Expression`s emit correctly.

Worth covering in tests: a list of function tear-offs, a list of `Type`
literals, a nested list, and an empty list.

## Status in this repo

Not waiting on the fix. `riverpod_di_generator` no longer routes the `Riverpod`
annotation through revive at all — `RiverpodReader.toExpression()` rebuilds it
from its four known fields (`keepAlive`, `dependencies`, `retry`, `name`) and
maps each `dependencies` entry itself. Once `dart_test_tools` is fixed that
local handling could be reconsidered, but rebuilding also lets us omit fields
that are at their default, so it is likely worth keeping regardless.
