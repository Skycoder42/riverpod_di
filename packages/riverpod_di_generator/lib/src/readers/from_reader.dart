import 'package:analyzer/dart/element/element.dart';
import 'package:riverpod_di/riverpod_di.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_helper/source_helper.dart';

import 'riverpod_reader.dart';

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

class FromReader(final ConstantReader _reader) {
  bool get exists => !_reader.isNull;

  bool get notifier => _reader.peek('notifier')?.boolValue ?? false;

  bool get read => _reader.peek('read')?.boolValue ?? false;

  String? providerName([Element? annotation]) {
    if (!exists) {
      return null;
    }

    final rawProvider = _reader.read('provider');
    if (rawProvider.isType) {
      final typeElement = rawProvider.typeValue.element;
      if (typeElement is! InterfaceElement) {
        throw InvalidGenerationSource(
          'Annotation $From requires a type that is a class.',
          element: annotation,
        );
      }

      return _providerName(typeElement, stripSuffix: 'Notifier');
    } else if (rawProvider.objectValue.toFunctionValue() case final element?) {
      return _providerName(element);
    } else if (rawProvider.isString) {
      return rawProvider.stringValue;
    } else {
      throw InvalidGenerationSource(
        'Annotation $From provider parameter must be a provider annotated '
        'class type or function, or a provider name in form of a string.',
        element: annotation,
      );
    }
  }

  String _providerName(Element element, {String? stripSuffix}) {
    final annotation = element.riverpod;
    if (annotation?.name case final name?) {
      return name;
    }

    var elementName = element.name;
    if (elementName == null) {
      throw InvalidGenerationSource(
        'Cannot watch provider from an element without a name.',
        element: element,
      );
    }

    if (stripSuffix != null && elementName.endsWith(stripSuffix)) {
      elementName = elementName.substring(
        0,
        elementName.length - stripSuffix.length,
      );
    }

    return '${elementName}Provider'.camel;
  }
}
