import 'package:analyzer/dart/element/element.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_injected/riverpod_injected.dart';
import 'package:source_gen/source_gen.dart';

@internal
extension DisposeMethodReaderX on MethodElement {
  static const _typeChecker = TypeChecker.typeNamed(
    DisposeMethod,
    inPackage: 'riverpod_injected',
  );

  bool get hasDisposeMethod => _typeChecker.hasAnnotationOf(this);
}
