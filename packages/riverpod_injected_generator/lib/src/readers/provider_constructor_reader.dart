import 'package:analyzer/dart/element/element.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_injected/riverpod_injected.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_helper/source_helper.dart';

@internal
extension ProviderConstructorReaderX on ExecutableElement {
  static const _typeChecker = TypeChecker.typeNamed(
    ProviderConstructor,
    inPackage: 'riverpod_injected',
  );

  bool get hasProviderConstructor => _typeChecker.hasAnnotationOf(this);

  void validateProviderConstructor() {
    if (this is ConstructorElement) {
      return;
    }

    if (!isStatic) {
      throw InvalidGenerationSource(
        'Only constructors and static methods can be '
        'annotated with $ProviderConstructor.',
        element: this,
      );
    }

    final clazz = enclosingElement;
    if (clazz is! ClassElement) {
      throw InvalidGenerationSource(
        'Unable to detect enclosing class.',
        element: this,
      );
    }

    final typeProvider = clazz.library.typeProvider;
    final classType = clazz.thisType;
    final classFutureType = typeProvider.futureType(classType);
    final classFutureOrType = typeProvider.futureOrType(classType);
    final isSupportedType =
        returnType.isAssignableTo(classFutureType) ||
        returnType.isAssignableTo(classFutureType) ||
        returnType.isAssignableTo(classFutureOrType);
    if (!isSupportedType) {
      throw InvalidGenerationSource(
        'A $ProviderConstructor annotated method must return '
        '${clazz.displayName} or a Future of it.',
        element: this,
      );
    }
  }
}
