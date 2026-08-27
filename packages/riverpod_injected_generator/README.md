# riverpod_injected

[![CI/CD for riverpod_injected](https://github.com/Skycoder42/riverpod_injected/actions/workflows/riverpod_injected_ci.yaml/badge.svg)](https://github.com/Skycoder42/riverpod_injected/actions/workflows/riverpod_injected_ci.yaml)
[![CI/CD for riverpod_injected_generator](https://github.com/Skycoder42/riverpod_injected/actions/workflows/riverpod_injected_generator_ci.yaml/badge.svg)](https://github.com/Skycoder42/riverpod_injected/actions/workflows/riverpod_injected_generator_ci.yaml)
[![Pub Version](https://img.shields.io/pub/v/riverpod_injected)](https://pub.dev/packages/riverpod_injected)
[![Pub Version](https://img.shields.io/pub/v/riverpod_injected_generator?label=pub%20riverpod_injected_generator)](https://pub.dev/packages/riverpod_injected_generator)

A small code generator for simple dependency injection via riverpod.

Annotate a class, get a provider that creates it — with every constructor
parameter watched from the provider of its own type. Asynchronous dependencies
are awaited for you, so an `async` service can depend on another `async` service
without a single `AsyncValue` in your own code.

```dart
@riverDi
class const Config();

@riverDiAsync
class Database {
  const new _();

  @providerConstructor
  static Future<Database> connect(Config config) async => const Database._();

  @disposeMethod
  Future<void> close() { /*...*/ }
}

@riverDiSingleton
class const Repository(final Database database, final Config config);
```

<details>
<summary>… generates (<code>.di.g.dart</code>)</summary>

```dart
@Riverpod()
Config config(Ref ref) => const Config();

@Riverpod()
FutureOr<Database> database(Ref ref) async {
  final $instance = await Database.connect(ref.watch(configProvider));
  ref.onDispose($instance.close);
  return $instance;
}

@Riverpod(keepAlive: true)
FutureOr<Repository> repository(Ref ref) async => Repository(
  await ref.watch(databaseProvider.future),
  ref.watch(configProvider),
);
```

</details>

Those functions are then picked up by
[`riverpod_generator`](https://pub.dev/packages/riverpod_generator), which turns
them into the actual `configProvider`, `databaseProvider` and
`repositoryProvider`.

## Table of contents

<!-- TOC -->
- [Features](#features)
- [How it works](#how-it-works)
- [Installation](#installation)
- [Usage](#usage)
  - [The annotations](#the-annotations)
  - [Choosing the constructor](#choosing-the-constructor)
  - [How parameters are resolved](#how-parameters-are-resolved)
  - [Naming providers](#naming-providers)
  - [Injecting explicitly with `@From`](#injecting-explicitly-with-from)
  - [Asynchronous chains](#asynchronous-chains)
  - [Disposal](#disposal)
  - [Forwarding riverpod options](#forwarding-riverpod-options)
- [Configuration](#configuration)
- [Limitations](#limitations)
- [Examples](#examples)
- [Documentation](#documentation)
<!-- TOC -->

## Features

- **Constructor injection** — every parameter is watched from the provider of
  its declared type, no registration and no service locator.
- **Automatic awaiting** — an async dependency is resolved via `.future` and
  awaited before your constructor runs.
- **Notifiers by type** — a parameter typed as a `@riverpod` notifier class is
  handed the notifier itself, so calling into it needs no boilerplate.
- **Any constructor shape** — primary, unnamed, named and factory constructors,
  static factory methods, field formals, `super.` parameters, optional and
  defaulted parameters, and the `Ref` itself.
- **Explicit wiring where you need it** — `@From` names the provider for
  abstractions, hand written providers, notifiers and `ref.read`.
- **Disposal** — `@disposeMethod` or the `onDispose` parameter register the
  teardown on the provider's `ref`.
- **Full riverpod interop** — `keepAlive`, `name`, `dependencies` and `retry`
  are forwarded verbatim, and generated providers mix freely with hand written
  ones.

## How it works

The package ships as two packages:

| Package                                                                    | Contents                                        | Dependency type   |
| -------------------------------------------------------------------------- | ----------------------------------------------- | ----------------- |
| [`riverpod_injected`](https://pub.dev/packages/riverpod_injected)                       | the annotations                                  | `dependencies`     |
| [`riverpod_injected_generator`](https://pub.dev/packages/riverpod_injected_generator)   | the builder                                      | `dev_dependencies` |

Generation happens in two steps, chained by `build_runner`:

```
your_file.dart          @riverDi annotated classes
      │
      ├─ riverpod_injected_generator ──► your_file.di.g.dart    provider functions
      │                                                    (@Riverpod annotated)
      └─ riverpod_generator ─────► your_file.g.dart       the actual providers
```

`riverpod_injected_generator` declares `runs_before: riverpod_generator`, so a single
`build_runner` invocation produces both parts. Because the generated functions
are plain `@Riverpod` functions, everything riverpod knows about them — code
completion, `custom_lint`, overrides in tests — keeps working.

## Installation

```yaml
dependencies:
  riverpod: <latest> # or flutter_riverpod / hooks_riverpod
  riverpod_annotation: <latest>
  riverpod_injected: <latest>

dev_dependencies:
  build_runner: <latest>
  riverpod_injected_generator: <latest>
  riverpod_generator: <latest>
```

`riverpod_injected` re-exports `riverpod_annotation`, so a single import is enough:

```dart
import 'package:riverpod_injected/riverpod_injected.dart';

part 'my_file.di.g.dart'; // riverpod_injected_generator
part 'my_file.g.dart'; // riverpod_generator
```

Then run the build as usual:

```sh
dart run build_runner build
```

Both builders apply automatically to any package that depends on them
(`auto_apply: dependents`), and `riverpod_injected_generator` only runs for files that
actually use one of its annotations.

## Usage

### The annotations

| Annotation                | Equivalent to                              | Provider                     |
| ------------------------- | ------------------------------------------ | ---------------------------- |
| `@riverDi`                | `@RiverDi(riverpod)`                       | auto disposed, synchronous   |
| `@riverDiSingleton`       | `@RiverDi(Riverpod(keepAlive: true))`      | `keepAlive`, synchronous     |
| `@riverDiAsync`           | `@RiverDi(riverpod, async: true)`          | auto disposed, asynchronous  |
| `@riverDiAsyncSingleton`  | `@RiverDi(Riverpod(keepAlive: true), async: true)` | `keepAlive`, asynchronous |

For anything beyond those four, use `@RiverDi` directly. Its first parameter is
the `Riverpod` annotation to put on the generated function, `async` marks the
provider as asynchronous and `onDispose` names a teardown function.

### Choosing the constructor

By default the primary or unnamed constructor is invoked. Annotate a different
constructor — or a static method — with `@providerConstructor` to use that one
instead:

```dart
@riverDi
class Cache {
  const new _();

  @providerConstructor
  const new createEmpty() = Cache._;
}
```

A `@providerConstructor` method must be `static` and return the class, or a
`Future`/`FutureOr` of it. Returning asynchronously requires the class to be
annotated as asynchronous. Only one constructor or method per class can carry
the annotation.

### How parameters are resolved

Every parameter of the invoked constructor is injected from the provider of its
declared type, watched via `ref.watch`. What that provider is — and what exactly
is taken from it — follows from how the type is declared:

| Declared type of the parameter        | Injected                                                     |
| ------------------------------------- | ------------------------------------------------------------ |
| a `@RiverDi` annotated class          | the created instance, awaited if that class is asynchronous   |
| a `@Riverpod` annotated notifier class | the **notifier**, i.e. `ref.watch(provider.notifier)`         |
| anything else                         | the value of the provider guessed from the type name          |

A notifier is injected as the notifier because that is the object holding the
logic you want to call — the built state is reachable through it, and rebuilding
your service on every state change is rarely what you want:

```dart
@riverpod
class CounterNotifier extends _$CounterNotifier {
  @override
  int build() => 0;

  void increment() => state++;
}

@riverDi
class const CounterController(final CounterNotifier counter);
```

The provider itself is resolved through riverpod, so the notifier is found under
the name riverpod actually gives it — `counterProvider` here, with the default
strip pattern removing the `Notifier` suffix. To watch the built value instead of
the notifier, name the provider explicitly with
[`@From`](#injecting-explicitly-with-from).

The last row of the table is a fallback rather than a feature: for a type that
carries no provider annotation at all, the name is guessed from the type name
alone. That works for a hand written provider following the naming convention
and produces an undefined name otherwise, so prefer `@From` there.

On top of that:

- **`Ref`** — a `Ref` parameter is handed the provider's own ref, so a class can
  manage its own lifecycle.
- **Optional/Defaulted parameters** — a parameter that has a default value keeps it and is
  left out of the generated call. Annotate it with `@From` to inject it anyway.
- **Field formals and `super.` parameters** — treated like ordinary parameters.

```dart
@riverDi
class Workshop {
  final Engine engine;

  new(Ref ref, this.engine) {
    ref.onDispose(() { /* … */ });
  }
}
```

One rule to keep in mind: a positional parameter with a default value cannot be
followed by an injected positional parameter, because the generated call would
have to skip it. Reorder them or make them named.

### Naming providers

The generated function is named after the class, and `riverpod_generator` then
derives the provider name from it — applying the same prefix, suffix and strip
pattern it applies to hand written providers. With the defaults, `class Repository`
becomes `repositoryProvider`, and the default strip pattern (`Notifier$`) turns
`class SettingsNotifier` into `settingsProvider`.

Dependencies are resolved against the same derived name, so both sides always
agree. An explicit name wins over the derived one and is honoured by consumers
as well:

```dart
@RiverDi(Riverpod(name: 'timeProvider'))
class const Clock();

@riverDi
class const ClockConsumer(final Clock clock); // watches timeProvider
```

If you customize the naming options of `riverpod_generator`, mirror them onto
this builder as well — see [Configuration](#configuration).

### Injecting explicitly with `@From`

`@From` states the provider a parameter comes from instead of deriving it from
the parameter type. It is required whenever the derivation cannot work or would
pick the wrong provider — most notably when a parameter is typed as an
abstraction:

```dart
abstract interface class Greeter {
  String greet(String name);
}

@riverDi
class const FriendlyGreeter() implements Greeter { /* … */ }

@riverDi
class const Welcome(@From(FriendlyGreeter) final Greeter greeter);
```

The provider can be named in three ways:

- the **`Type`** of a `@RiverDi` or `@Riverpod` annotated class
- a **function** annotated with `@Riverpod`
- a **`String`** holding the name of the generated provider variable

And there are three constructors, each of which takes an optional
`read: true` to use `ref.read` instead of `ref.watch`:

| Constructor      | Injects                        | Generates                          |
| ---------------- | ------------------------------ | ---------------------------------- |
| `@From(…)`       | the value of the provider      | `ref.watch(provider)`              |
| `@From.notifier(…)` | the notifier itself         | `ref.watch(provider.notifier)`     |
| `@From.async(…)` | the awaited value              | `await ref.watch(provider.future)` |

Because `@From` states the reference in full, it also overrides the notifier
default: `@From(CounterNotifier)` injects the built value, while
`@From.notifier(CounterNotifier)` injects the notifier — the same thing the bare
type would have given you. `@From.notifier` only accepts the `Type` of a
`@Riverpod` annotated notifier class.

```dart
@riverDiAsyncSingleton
class const Service(
  @From(externalFunc) int value,
  @From(CounterNotifier) int count,
  @From.notifier(CounterNotifier) CounterNotifier counter,
  @From.async(remoteConfig, read: true) RemoteConfig config,
  @From('legacyServiceProvider') LegacyService legacy,
);
```

### Asynchronous chains

A class annotated as asynchronous produces a `FutureOr` returning provider, and
its async dependencies are awaited automatically. Depending on an async provider from a synchronous class is an
error that tells you to add `async: true`.

The reverse is fine: an async annotation over a fully synchronous constructor
simply never awaits anything, which is handy when a class is expected to gain
async dependencies later.

Note that `@From` states the whole reference itself, so reaching for an async
provider takes `@From.async` — plain `@From` would hand over the raw
`AsyncValue`.

An asynchronous notifier class behaves the same way from both sides: by type it
hands over the notifier, which needs no awaiting, and `@From.async` hands over
its awaited state.

See [`async_chain_example.dart`](https://github.com/Skycoder42/riverpod_injected/blob/main/packages/riverpod_injected_generator/example/async_chain_example.dart)
for the full picture.

### Disposal

Mark a method with `@disposeMethod` to have it registered via `ref.onDispose`:

```dart
@riverDi
class Connection {
  @disposeMethod
  void close() {}
}
```

An instance method must have no required parameters, as it is torn off the
created instance. A static method must accept the instance as its first
positional parameter, which makes it the way to dispose classes that cannot hold
the annotation themselves — for those, `@RiverDi` takes an `onDispose` function
of the same shape:

```dart
@RiverDi(riverpod, onDispose: _closeCache)
class const Cache();

void _closeCache(Cache cache) {}
```

Only one method per class can carry `@disposeMethod`, and it cannot be combined
with `onDispose`. Async providers register the awaited instance, not the future.

### Forwarding riverpod options

The `Riverpod` annotation passed to `@RiverDi` is forwarded verbatim, so
`keepAlive`, `name`, `dependencies` and `retry` all work as they do on a hand
written provider:

```dart
@RiverDi(
  Riverpod(keepAlive: true, retry: _retryTwice, dependencies: [appVersion]),
)
class const Scoped(@From(appVersion) final String version);
```

## Configuration

The builder is configured in your `build.yaml` under
`riverpod_injected_generator:riverpod_injected_generator`. It understands the same provider
naming options as `riverpod_generator`, and it has to, because it resolves
dependencies by the name the provider will end up with. If you set any of them,
set them on both builders:

```yaml
targets:
  $default:
    builders:
      riverpod_generator:
        options: &riverpod_options
          provider_name_prefix: ""
          provider_name_suffix: "Provider"
          provider_name_strip_pattern: "Notifier$"
      riverpod_injected_generator:
        options: *riverpod_options
```

| Option                        | Default      | Effect                                     |
| ----------------------------- | ------------ | ------------------------------------------ |
| `provider_name_prefix`        | `""`         | prefix of the generated provider variable  |
| `provider_name_suffix`        | `"Provider"` | suffix of the generated provider variable  |
| `provider_name_strip_pattern` | `"Notifier$"`| regex stripped from the class name         |

The usual `build_runner` knobs — `generate_for`, `enabled`, `runs_before` — apply
as well.

## Limitations

- **No family providers.** Neither generating them nor injecting from one is
  supported; a parameter resolving to a family provider is a build error.
- **Abstractions need `@From`.** Resolution works off the declared parameter
  type, so an interface with no provider of its own has to be wired explicitly.
- **Classes only.** `@RiverDi` cannot be placed on functions — those are already
  covered by `@riverpod` itself.
- **Async is explicit.** A constructor returning a `Future` or depending on an
  async provider requires the class to be annotated as asynchronous.

## Examples

The [example directory](https://github.com/Skycoder42/riverpod_injected/tree/main/packages/riverpod_injected_generator/example)
holds a commented file per topic, each next to the code it generates:

| Example                                                                                                                                | Topic                                                            |
| -------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| [`riverpod_injected_generator_example.dart`](https://github.com/Skycoder42/riverpod_injected/blob/main/packages/riverpod_injected_generator/example/riverpod_injected_generator_example.dart) | a tour of everything the generator supports                       |
| [`constructor_shapes_example.dart`](https://github.com/Skycoder42/riverpod_injected/blob/main/packages/riverpod_injected_generator/example/constructor_shapes_example.dart)       | field formals, `super.` parameters, defaults, optionals and `Ref` |
| [`interfaces_example.dart`](https://github.com/Skycoder42/riverpod_injected/blob/main/packages/riverpod_injected_generator/example/interfaces_example.dart)                       | injecting an abstraction via `@From`                              |
| [`async_chain_example.dart`](https://github.com/Skycoder42/riverpod_injected/blob/main/packages/riverpod_injected_generator/example/async_chain_example.dart)                     | asynchronous dependency chains                                    |
| [`dispose_example.dart`](https://github.com/Skycoder42/riverpod_injected/blob/main/packages/riverpod_injected_generator/example/dispose_example.dart)                             | `@disposeMethod` and `onDispose`                                  |
| [`naming_example.dart`](https://github.com/Skycoder42/riverpod_injected/blob/main/packages/riverpod_injected_generator/example/naming_example.dart)                               | name derivation and forwarded riverpod options                    |
| [`cross_library_example.dart`](https://github.com/Skycoder42/riverpod_injected/blob/main/packages/riverpod_injected_generator/example/cross_library_example.dart)                 | dependencies declared in another library                          |

## Documentation

The API documentation is available at
[pub.dev](https://pub.dev/documentation/riverpod_injected/latest/riverpod_injected/riverpod_injected-library.html).
Bugs and feature requests belong into the
[issue tracker](https://github.com/Skycoder42/riverpod_injected/issues).

Licensed under the [BSD 3-Clause License](https://github.com/Skycoder42/riverpod_injected/blob/main/LICENSE).
