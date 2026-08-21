import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_test_tools/code_gen.dart';
import 'package:riverpod_di/riverpod_di.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_helper/source_helper.dart';

import 'readers/river_di_reader.dart';
import 'types.dart';

class const RiverpodDiGenerator()
    extends GeneratorForAnnotation<RiverDi>
    with DartGeneratorMixin {
  static const _refRef = Reference('ref');

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSource(
        '@$RiverDi can only be used on classes',
        element: element,
      );
    }

    final reader = RiverDiReader(annotation);

    return createDartCode(_buildProvider(element, reader), scoped: false);
  }

  Method _buildProvider(ClassElement element, RiverDiReader reader) => Method(
    (b) => b
      ..name = element.name!.camel
      ..annotations.add(reader.annotation)
      ..returns = element.toReference()
      ..requiredParameters.add(
        Parameter(
          (b) => b
            ..name = _refRef.symbol!
            ..type = Types.$Ref,
        ),
      )
      ..lambda = true
      ..body = _buildBody(element, reader).statement,
  );

  Expression _buildBody(ClassElement element, RiverDiReader reader) {
    final type = element.toReference();

    final constructor =
        element.primaryConstructor ?? element.unnamedConstructor;

    if (constructor == null) {
      throw InvalidGenerationSource(
        'Class has no primary or unnamed constructor!',
        element: element,
      );
    }

    final posArgs = constructor.formalParameters
        .where((p) => p.isPositional)
        .map(_watchReference)
        .toList(growable: false);
    final namedArgs = {
      for (final p in constructor.formalParameters.where((p) => p.isNamed))
        p.name!: _watchReference(p),
    };

    final noArgs = posArgs.isEmpty && namedArgs.isEmpty;
    return switch (constructor) {
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
  }

  Expression _watchReference(FormalParameterElement param) {
    final baseName = param.type.element?.name?.camel;
    if (baseName == null) {
      throw InvalidGenerationSource(
        'Cannot detect default provider name from parameter type '
        '${param.type.getDisplayString()}.',
        element: param,
      );
    }
    return _refRef.property('watch').call([refer('${baseName}Provider')]);
  }
}
