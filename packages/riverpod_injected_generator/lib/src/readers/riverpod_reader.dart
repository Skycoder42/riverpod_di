import 'package:analyzer/dart/element/element.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_injected/riverpod_injected.dart';
import 'package:source_gen/source_gen.dart';

@internal
extension RiverpodX on Element {
  static const _typeChecker = TypeChecker.typeNamed(
    Riverpod,
    inPackage: 'riverpod_annotation',
  );

  RiverpodReader? get riverpod {
    final annotation = _typeChecker.firstAnnotationOf(this);
    final reader = ConstantReader(annotation);
    return reader.isNull ? null : RiverpodReader(reader);
  }
}

@internal
// ignore: public_member_api_docs false positive
class RiverpodReader(final ConstantReader _reader) {
  String? get name => _reader.peek('name')?.stringValue;
}
