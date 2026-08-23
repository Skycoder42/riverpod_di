import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_test_tools/dart_test_tools.dart';
import 'package:riverpod_di/riverpod_di.dart';
import 'package:source_gen/source_gen.dart';

extension RiverpodX on Element {
  static const _typeChecker = TypeChecker.typeNamed(
    Riverpod,
    inPackage: 'riverpod_annotation',
  );

  RiverpodReader get riverpod {
    final annotation = _typeChecker.firstAnnotationOf(this);
    final reader = ConstantReader(annotation);
    return RiverpodReader(reader);
  }
}

class RiverpodReader(final ConstantReader _reader) {
  bool get exists => !_reader.isNull;

  String? get name => _reader.peek('name')?.stringValue;

  Expression toExpression() => exists
      ? _reader.toExpression()
      : refer('riverpod', 'package:riverpod_di:riverpod_di.dart');
}
