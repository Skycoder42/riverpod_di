import 'package:code_builder/code_builder.dart';

sealed class Types {
  static TypeReference $FutureOr([Reference? type]) => TypeReference((b) {
    b
      ..symbol = 'FutureOr'
      ..url = 'dart:async'
      ..types.addAll([?type]);
  });

  static final $Ref = TypeReference(
    (b) => b
      ..symbol = 'Ref'
      ..url = 'package:riverpod_di:riverpod_di.dart',
  );
}
