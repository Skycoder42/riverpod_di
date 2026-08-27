import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_test_tools/code_gen.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_injected/riverpod_injected.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_helper/source_helper.dart';

import 'provider_resolver.dart';
import 'readers/dispose_method_reader.dart';
import 'readers/from_reader.dart';
import 'readers/provider_constructor_reader.dart';
import 'readers/river_di_reader.dart';
import 'types.dart';

@internal
// ignore: public_member_api_docs false positive
class RiverpodDiGenerator(final BuilderOptions options)
    extends GeneratorForAnnotation<RiverDi>
    with DartGeneratorMixin {
  static const _refRef = Reference('ref');
  static const _instanceRef = Reference(r'$instance');

  static const _refTypeChecker = TypeChecker.typeNamed(
    Ref,
    inPackage: 'riverpod',
  );

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

    final riverDi = RiverDiReader(annotation);

    return createDartCode(
      await _buildProvider(buildStep, element, riverDi),
      scoped: false,
    );
  }

  Future<Method> _buildProvider(
    BuildStep buildStep,
    ClassElement element,
    RiverDiReader riverDi,
  ) async {
    final methodBuilder = MethodBuilder()
      ..name = element.name!.camel
      ..annotations.add(riverDi.annotation.toExpression())
      ..returns = riverDi.async
          ? Types.$FutureOr(element.toReference())
          : element.toReference()
      ..requiredParameters.add(
        Parameter(
          (b) => b
            ..name = _refRef.symbol!
            ..type = Types.$Ref,
        ),
      )
      ..modifier = riverDi.async ? .async : null;

    final (invocation, isConst) = await _buildInvocation(
      buildStep,
      element,
      riverDi,
    );
    final disposeRef = _getDisposeRef(element, riverDi);

    if (disposeRef == null) {
      methodBuilder
        ..lambda = true
        ..body = invocation.statement;
    } else {
      methodBuilder.body = Block.of([
        if (isConst)
          declareConst(_instanceRef.symbol!).assign(invocation).statement
        else
          declareFinal(_instanceRef.symbol!).assign(invocation).statement,
        _refRef.property('onDispose').call([disposeRef]).statement,
        _instanceRef.returned.statement,
      ]);
    }

    return methodBuilder.build();
  }

  Expression? _getDisposeRef(ClassElement element, RiverDiReader riverDi) {
    // find annotated dispose methods
    final disposeMethods = element.methods
        .where((m) => m.hasDisposeMethod)
        .toList(growable: false);
    if (disposeMethods.length > 1) {
      throw InvalidGenerationSource(
        'Cannot have more then a single method marked as @dispose.',
        todo: 'Remove @dispose from all but one method.',
        element: disposeMethods[1],
      );
    }

    // check for class annotation method
    ExecutableElement? disposeMethod = disposeMethods.firstOrNull;
    if (riverDi.onDispose case final onDispose?) {
      if (disposeMethod != null) {
        throw InvalidGenerationSource(
          'Cannot have a method marked as @dispose '
          'and an onDispose parameter to @RiverDi.',
          todo: 'Remove @dispose from the method or the onDispose parameter.',
          element: disposeMethods.first,
        );
      } else {
        disposeMethod = onDispose;
      }
    }
    // resolve method type for invocation
    return switch (disposeMethod) {
      // none => null
      null => null,

      // non static instance methods must have no required parameters
      MethodElement(isStatic: false, :final name?, :final formalParameters)
          when !formalParameters.any((p) => p.isRequired) =>
        _instanceRef.property(name),

      // static or top level function
      // must take a single required param of the class type
      //
      ExecutableElement(
        isStatic: true,
        formalParameters: [
          FormalParameterElement(:final type, isRequiredPositional: true),
          ...final others,
        ],
      )
          when element.thisType.isAssignableTo(type) &&
              !others.any((p) => p.isRequired) =>
        Method(
          (b) => b
            ..lambda = true
            ..body = disposeMethod!.toExpression().call(const [
              _instanceRef,
            ]).code,
        ).closure,

      // all others => unsupported
      _ => throw InvalidGenerationSource(
        'A dispose method must be an instance method or take the instance '
        'as first positional parameter and have no other required parameters.',
        element: disposeMethod,
      ),
    };
  }

  Future<(Expression, bool)> _buildInvocation(
    BuildStep buildStep,
    ClassElement element,
    RiverDiReader riverDi,
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
        'Class has no primary or unnamed constructor!',
        todo: 'Create one or annotate another with $ProviderConstructor.',
        element: element,
      );
    }

    final bool returnsAsync;
    switch (constructorOrMethod.returnType) {
      // async case 1: Not marked as async
      case DartType(isDartAsyncFuture: true) ||
              DartType(isDartAsyncFutureOr: true)
          when !riverDi.async:
        throw InvalidGenerationSource(
          'Constructor returns Future or FutureOr, but is not marked as async!',
          todo:
              'Use @RiverDi(async: true) or @riverDiAsync or '
              '@riverDiAsyncSingleton.',
          element: constructorOrMethod,
        );
      // async case 2: Marked as async, but return type is not assignable
      case InterfaceType(
                isDartAsyncFuture: true,
                typeArguments: [final inner],
              ) ||
              InterfaceType(
                isDartAsyncFutureOr: true,
                typeArguments: [final inner],
              )
          when !inner.isAssignableTo(element.thisType):
        throw InvalidGenerationSource(
          'Constructor returns an async value of $inner, '
          'which is not assignable to ${element.thisType}',
          todo:
              'Change the return type to be assignable to ${element.thisType}',
          element: constructorOrMethod,
        );
      // async case 3: Marked as async and return type matches => OK
      case InterfaceType(isDartAsyncFuture: true) ||
          InterfaceType(isDartAsyncFutureOr: true):
        returnsAsync = true;
      // sync case 1: Return type is not assignable
      case final type when !type.isAssignableTo(element.thisType):
        throw InvalidGenerationSource(
          'Constructor returns a value of $type, '
          'which is not assignable to ${element.thisType}',
          todo:
              'Change the return type to be assignable to ${element.thisType}',
          element: constructorOrMethod,
        );
      // sync case 2: Return type matches => OK
      case _:
        returnsAsync = false;
    }

    final positionalParams = constructorOrMethod.formalParameters
        .where((p) => p.isPositional)
        .toList(growable: false);
    _validatePositionalDefaults(positionalParams);

    final posArgs = [
      for (final p in positionalParams.where(_isInjected))
        await _watchReference(buildStep, riverDi, p),
    ];
    final namedArgs = {
      for (final p in constructorOrMethod.formalParameters.where(
        (p) => p.isNamed && _isInjected(p),
      ))
        p.name!: await _watchReference(buildStep, riverDi, p),
    };

    final noArgs = posArgs.isEmpty && namedArgs.isEmpty;

    final (invocation, isConst) = switch (constructorOrMethod) {
      MethodElement(:final name?, isStatic: true) => (
        type.property(name)(posArgs, namedArgs),
        false,
      ),
      ConstructorElement(name: final name?, isConst: true)
          when noArgs && name != 'new' =>
        (type.constInstanceNamed(name, const []), true),
      ConstructorElement(isConst: true) when noArgs => (
        type.constInstance(const []),
        true,
      ),
      ConstructorElement(name: final name?) when name != 'new' => (
        type.newInstanceNamed(name, posArgs, namedArgs),
        false,
      ),
      _ => (type.newInstance(posArgs, namedArgs), false),
    };

    return (returnsAsync ? invocation.awaited : invocation, isConst);
  }

  /// Whether [param] should be resolved to a provider and injected.
  ///
  /// A parameter with a default value is left to that default, unless it
  /// explicitly opts back in via [From].
  bool _isInjected(FormalParameterElement param) =>
      !param.hasDefaultValue || param.from.exists;

  /// Ensures skipped positional parameters are all trailing ones.
  void _validatePositionalDefaults(List<FormalParameterElement> params) {
    final firstSkipped = params.indexWhere((p) => !_isInjected(p));
    if (firstSkipped == -1) {
      return;
    }

    final lastInjected = params.lastIndexWhere(_isInjected);
    if (lastInjected > firstSkipped) {
      throw InvalidGenerationSource(
        'Positional parameter has a default value, but a later positional '
        'parameter is still injected.',
        todo:
            'Annotate it with $From to inject it as well, or move it behind '
            'the injected parameters.',
        element: params[firstSkipped],
      );
    }
  }

  Future<Expression> _watchReference(
    BuildStep buildStep,
    RiverDiReader riverDi,
    FormalParameterElement param,
  ) async {
    final fromReader = param.from;
    if (!fromReader.exists && _refTypeChecker.isExactlyType(param.type)) {
      return _refRef;
    }

    final paramTypeElement = param.type.element;
    var resolvedProvider = switch (fromReader.provider(param)) {
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
      NamedProviderRef(:final name) => ResolvedProvider(provider: refer(name)),
      _ => throw InvalidGenerationSource(
        'Unable to automatically detect provider '
        'for parameter of type ${param.type}',
        element: param,
      ),
    };

    resolvedProvider = resolvedProvider.adjust(
      isNotifier: fromReader.notifier,
      isAsync: fromReader.async,
    );

    if (resolvedProvider.isAsync && !riverDi.async) {
      throw InvalidGenerationSource(
        'Referenced provider is async, but the annotated class is not!',
        todo:
            'Use @RiverDi(async: true) or @riverDiAsync or '
            '@riverDiAsyncSingleton.',
        element: param,
      );
    }

    final refMethod = (fromReader.read ?? false) ? 'read' : 'watch';

    final result = _refRef.property(refMethod).call([
      resolvedProvider.toExpression(),
    ]);
    return resolvedProvider.isAsync ? result.awaited : result;
  }
}
