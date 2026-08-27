import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_test_tools/dart_test_tools.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_injected/riverpod_injected.dart';
import 'package:source_gen/source_gen.dart';

import '../types.dart';

@internal
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

@internal
// ignore: public_member_api_docs false positive
class RiverpodReader(final ConstantReader _reader) {
  bool get exists => !_reader.isNull;

  String? get name => _reader.peek('name')?.stringValue;

  bool get keepAlive => _reader.peek('keepAlive')?.boolValue ?? false;

  ExecutableElement? get retry =>
      _reader.peek('retry')?.objectValue.toFunctionValue();

  List<DartObject>? get dependencies =>
      _reader.peek('dependencies')?.objectValue.toListValue();

  /// Rebuilds the annotation from its fields instead of reviving it.
  ///
  /// Reviving turns [Riverpod.dependencies] into a list of raw constant
  /// objects, which cannot be emitted as a literal. Only fields that differ
  /// from their default are emitted.
  Expression toExpression() {
    if (!exists) {
      return Types.$riverpod;
    } else {
      return _reader.toExpression();
    }
  }
}
