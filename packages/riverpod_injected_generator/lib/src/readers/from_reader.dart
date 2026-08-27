import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_injected/riverpod_injected.dart';
import 'package:source_gen/source_gen.dart';

@internal
extension FromReaderX on FormalParameterElement {
  static const _typeChecker = TypeChecker.typeNamed(
    From,
    inPackage: 'riverpod_injected',
  );

  FromReader get from {
    final annotation = _typeChecker.firstAnnotationOf(this);
    final reader = ConstantReader(annotation);
    return FromReader(reader);
  }
}

@internal
sealed class ProviderRef;
@internal
// ignore: public_member_api_docs false positive
class TypeProviderRef(final DartType type) extends ProviderRef;
@internal
// ignore: public_member_api_docs false positive
class FunctionProviderRef(final ExecutableElement element) extends ProviderRef;
@internal
// ignore: public_member_api_docs false positive
class NamedProviderRef(final String name) extends ProviderRef;

@internal
// ignore: public_member_api_docs false positive
class FromReader(final ConstantReader _reader) {
  bool get exists => !_reader.isNull;

  bool? get notifier => _reader.peek('notifier')?.boolValue;

  bool? get async => _reader.peek('async')?.boolValue;

  bool? get read => _reader.peek('read')?.boolValue;

  ProviderRef? provider([Element? annotation]) {
    if (!exists) {
      return null;
    }

    final rawProvider = _reader.read('provider');
    if (rawProvider.isType) {
      return TypeProviderRef(rawProvider.typeValue);
    } else if (rawProvider.objectValue.toFunctionValue() case final element?) {
      return FunctionProviderRef(element);
    } else if (rawProvider.isString) {
      return NamedProviderRef(rawProvider.stringValue);
    } else {
      throw InvalidGenerationSource(
        'Annotation $From provider parameter must be a provider annotated '
        'class type or function, or a provider name in form of a string.',
        element: annotation,
      );
    }
  }
}
