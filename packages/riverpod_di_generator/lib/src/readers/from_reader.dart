import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:riverpod_di/riverpod_di.dart';
import 'package:source_gen/source_gen.dart';

extension FromReaderX on FormalParameterElement {
  static const _typeChecker = TypeChecker.typeNamed(
    From,
    inPackage: 'riverpod_di',
  );

  FromReader get from {
    final annotation = _typeChecker.firstAnnotationOf(this);
    final reader = ConstantReader(annotation);
    return FromReader(reader);
  }
}

sealed class ProviderRef;
class TypeProviderRef(final DartType type) extends ProviderRef;
class FunctionProviderRef(final ExecutableElement element) extends ProviderRef;
class NamedProviderRef(final String name) extends ProviderRef;

class FromReader(final ConstantReader _reader) {
  bool get exists => !_reader.isNull;

  bool get notifier => _reader.peek('notifier')?.boolValue ?? false;

  bool get async => _reader.peek('async')?.boolValue ?? false;

  bool get read => _reader.peek('read')?.boolValue ?? false;

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
