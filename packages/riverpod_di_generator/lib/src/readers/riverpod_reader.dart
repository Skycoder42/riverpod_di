import 'package:analyzer/dart/element/element.dart';
import 'package:riverpod_di/riverpod_di.dart';
import 'package:source_gen/source_gen.dart';

extension RiverpodX on Element {
  static const _typeChecker = TypeChecker.typeNamed(
    Riverpod,
    inPackage: 'riverpod_annotation',
  );

  RiverpodReader? get riverpod {
    final annotation = _typeChecker.firstAnnotationOf(_typeChecker);
    final reader = ConstantReader(annotation);
    return reader.isNull ? null : RiverpodReader(reader);
  }
}

class RiverpodReader(final ConstantReader _reader) {
  String get name => _reader.read('name').stringValue;
}
