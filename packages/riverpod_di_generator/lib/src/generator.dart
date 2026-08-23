import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_test_tools/code_gen.dart';
import 'package:riverpod_di/riverpod_di.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_helper/source_helper.dart';

import 'provider_resolver.dart';
import 'readers/from_reader.dart';
import 'readers/provider_constructor_reader.dart';
import 'readers/river_di_reader.dart';
import 'types.dart';

class RiverpodDiGenerator(final BuilderOptions options)
    extends GeneratorForAnnotation<RiverDi>
    with DartGeneratorMixin {
  static const _refRef = Reference('ref');

  late final providerResolver = ProviderResolver(options);

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSource(
        '@$RiverDi can only be used on classes',
        element: element,
      );
    }

    final reader = RiverDiReader(annotation);

    return createDartCode(
      await _buildProvider(buildStep, element, reader),
      scoped: false,
    );
  }

  Future<Method> _buildProvider(
    BuildStep buildStep,
    ClassElement element,
    RiverDiReader reader,
  ) async {
    final (body, isAsync) = await _buildBody(buildStep, element, reader);
    return Method(
      (b) => b
        ..name = element.name!.camel
        ..annotations.add(reader.annotation.toExpression())
        ..returns = isAsync
            ? Types.$FutureOr(element.toReference())
            : element.toReference()
        ..requiredParameters.add(
          Parameter(
            (b) => b
              ..name = _refRef.symbol!
              ..type = Types.$Ref,
          ),
        )
        ..lambda = true
        ..body = body.statement,
    );
  }

  Future<(Expression, bool)> _buildBody(
    BuildStep buildStep,
    ClassElement element,
    RiverDiReader reader,
  ) async {
    final type = element.toReference();

    final annotated = element.constructors
        .cast<ExecutableElement>()
        .followedBy(element.methods)
        .where((c) => c.hasProviderConstructor)
        .toList(growable: false);

    final constructorOrMethod = switch (annotated) {
      [] => element.primaryConstructor ?? element.unnamedConstructor,
      [final single] => single..validateProviderConstructor(),
      _ => throw InvalidGenerationSource(
        'Multiple constructors or methods are annotated with '
        '$ProviderConstructor. Only a single one can be.',
        element: element,
      ),
    };

    if (constructorOrMethod == null) {
      throw InvalidGenerationSource(
        'Class has no primary or unnamed constructor! '
        'Create one or annotate another with $ProviderConstructor.',
        element: element,
      );
    }

    final posArgs = [
      for (final p in constructorOrMethod.formalParameters.where(
        (p) => p.isPositional,
      ))
        await _watchReference(buildStep, p),
    ];
    final namedArgs = {
      for (final p in constructorOrMethod.formalParameters.where(
        (p) => p.isNamed,
      ))
        p.name!: await _watchReference(buildStep, p),
    };

    final noArgs = posArgs.isEmpty && namedArgs.isEmpty;
    final invocation = switch (constructorOrMethod) {
      MethodElement(:final name?, isStatic: true) => type.property(name)(
        posArgs,
        namedArgs,
      ),
      ConstructorElement(name: final name?, isConst: true)
          when noArgs && name != 'new' =>
        type.constInstanceNamed(name, const []),
      ConstructorElement(isConst: true) when noArgs => type.constInstance(
        const [],
      ),
      ConstructorElement(name: final name?) when name != 'new' =>
        type.newInstanceNamed(name, posArgs, namedArgs),
      _ => type.newInstance(posArgs, namedArgs),
    };

    if (constructorOrMethod.returnType
        case DartType(isDartAsyncFuture: true) ||
            DartType(isDartAsyncFutureOr: true)) {
      return (invocation, true);
    } else {
      return (invocation, false);
    }
  }

  Future<Expression> _watchReference(
    BuildStep buildStep,
    FormalParameterElement param,
  ) async {
    final fromReader = param.from;
    final paramTypeElement = param.type.element;
    final providerRef = switch (fromReader.provider(param)) {
      null when paramTypeElement != null =>
        await providerResolver.resolveProviderFor(
          buildStep,
          param,
          paramTypeElement,
        ),
      TypeProviderRef(type: DartType(:final element?)) =>
        await providerResolver.resolveProviderFor(buildStep, param, element),
      FunctionProviderRef(:final element) =>
        await providerResolver.resolveProviderFor(buildStep, param, element),
      NamedProviderRef(:final name) => refer(name),
      _ => throw InvalidGenerationSource(
        'Unable to automatically detect provider '
        'for parameter of type ${param.type}',
        element: param,
      ),
    };

    final refMethod = fromReader.read ? 'read' : 'watch';

    return _refRef.property(refMethod).call([providerRef]);
  }
}
