import 'package:analyzer/dart/element/element.dart';
import 'package:riverpod_di/riverpod_di.dart';
import 'package:source_gen/source_gen.dart';

import 'riverpod_reader.dart';

extension RiverDiX on Element {
  static const _typeChecker = TypeChecker.typeNamed(
    RiverDi,
    inPackage: 'riverpod_di',
  );

  RiverDiReader? get riverDi {
    final annotation = _typeChecker.firstAnnotationOf(this);
    final reader = ConstantReader(annotation);
    return reader.isNull ? null : RiverDiReader(reader);
  }
}

class RiverDiReader(final ConstantReader _reader) {
  RiverpodReader get annotation => RiverpodReader(_reader.read('annotation'));

  bool get async => _reader.read('async').boolValue;

  ExecutableElement? get onDispose =>
      _reader.peek('onDispose')?.objectValue.toFunctionValue();
}
