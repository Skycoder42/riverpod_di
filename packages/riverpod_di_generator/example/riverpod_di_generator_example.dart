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

@riverDiAsync
class FromFuture {
  const new _();

  @providerConstructor
  static Future<FromFuture> createInstance() async => const ._();
}

@riverDiAsync
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

@riverpod
Future<int> externalAsync(Ref ref) async => 42;

@riverpod
class AsyncExternalNotifier extends _$AsyncExternalNotifier {
  @override
  Future<int> build() async => 42;
}

@riverDiAsyncSingleton
class FromExternal(
  @From(externalFunc) int func,
  @From(ExternalNotifier, read: true) int clazz,
  @From.notifier(ExternalNotifier) ExternalNotifier notifier,
  @From.async(externalAsync, read: true) int async,
  @From.async(AsyncExternalNotifier) int asyncNotifier,
  AsyncExternalNotifier auto,
  @From('externalFuncProvider') int named,
);

@riverDi
class Dispose1 {
  @disposeMethod
  void dispose() {}
}

@riverDi
class Dispose2 {
  @disposeMethod
  static void dispose(Dispose2 _) {}

  static void disposeOther(Dispose3 _) {}
}

@RiverDi(riverpod, onDispose: Dispose2.disposeOther)
class Dispose3;

void _dispose4(Dispose4 _) {}

@RiverDi(riverpod, onDispose: _dispose4)
class Dispose4;
