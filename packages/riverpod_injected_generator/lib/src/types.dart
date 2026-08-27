import 'package:code_builder/code_builder.dart';
import 'package:meta/meta.dart';

@internal
sealed class Types {
  static const _riverpodDiUrl =
      'package:riverpod_injected/riverpod_injected.dart';

  static TypeReference $FutureOr([Reference? type]) => TypeReference((b) {
    b
      ..symbol = 'FutureOr'
      ..url = 'dart:async'
      ..types.addAll([?type]);
  });

  static final $Ref = TypeReference(
    (b) => b
      ..symbol = 'Ref'
      ..url = _riverpodDiUrl,
  );

  static final $Riverpod = TypeReference(
    (b) => b
      ..symbol = 'Riverpod'
      ..url = _riverpodDiUrl,
  );

  static const $riverpod = Reference('riverpod', _riverpodDiUrl);
}
