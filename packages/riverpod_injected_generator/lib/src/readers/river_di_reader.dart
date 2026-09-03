import 'package:analyzer/dart/element/element.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_injected/riverpod_injected.dart';
import 'package:source_gen/source_gen.dart';

@internal
extension RiverDiX on Element {
  static const _typeChecker = TypeChecker.typeNamed(
    RiverDi,
    inPackage: 'riverpod_injected',
  );

  bool get hasRiverDi => _typeChecker.hasAnnotationOf(this);

  RiverDiReader? get riverDi {
    final annotation = _typeChecker.firstAnnotationOf(this);
    final reader = ConstantReader(annotation);
    return reader.isNull ? null : RiverDiReader(reader);
  }
}

@internal
// ignore: public_member_api_docs false positive
class RiverDiReader(final ConstantReader _reader) {
  bool get async => _reader.read('async').boolValue;

  ExecutableElement? get onDispose =>
      _reader.peek('onDispose')?.objectValue.toFunctionValue();

  String? get name => _reader.peek('name')?.stringValue;

  bool get keepAlive => _reader.peek('keepAlive')?.boolValue ?? false;

  ExecutableElement? get retry =>
      _reader.peek('retry')?.objectValue.toFunctionValue();

  List<ConstantReader>? get dependencies => _reader
      .peek('dependencies')
      ?.objectValue
      .toListValue()
      ?.map(ConstantReader.new)
      .toList();
}
