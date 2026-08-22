// ignore_for_file: avoid_unused_constructor_parameters for testing

import 'package:riverpod_di/riverpod_di.dart';

part 'riverpod_di_generator_example.di.g.dart';
part 'riverpod_di_generator_example.g.dart';

@riverDi
class const TestSimple();

@riverDi
class const TestReferring1(TestSimple simple);

@riverDi
class const TestReferring2.create(
  TestSimple simple, {
  TestReferring1? referring1,
});

@riverDi
class Basic;

@riverDi
class BasicDefault {
  new(Basic basic);
}

@riverDi
class BasicNamed {
  @providerConstructor
  new named(Basic basic);
}

@riverDi
class Factory {
  factory() => _Factory();
}

class _Factory implements Factory;

@riverDi
class FromMethod {
  const new _();

  @providerConstructor
  static FromMethod createInstance() => const ._();
}

@riverDi
class const Competing.primary() {
  const factory() = Competing.primary;

  @providerConstructor
  const factory internal() = Competing.primary;
}

@riverDi
class FromFuture {
  const new _();

  @providerConstructor
  static Future<FromFuture> createInstance() async => const ._();
}

@riverDi
class FromFutureOr {
  const new _();

  @providerConstructor
  static FutureOr<FromFutureOr> createInstance() => const ._();
}

@riverpod
int externalFunc(Ref ref) => 42;

@riverpod
class ExternalNotifier extends _$ExternalNotifier {
  @override
  int build() => 42;
}

@riverDi
class FromExternal(
  @From(externalFunc) int func,
  @From(ExternalNotifier) int clazz,
  @From.notifier(ExternalNotifier) ExternalNotifier notifier,
);
