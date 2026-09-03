// Teardown logic that runs when a provider is disposed: either a method of the
// class marked with `@disposeMethod`, or a function named via the `onDispose`
// parameter of `@RiverDi`.

import 'package:riverpod_injected/riverpod_injected.dart';

part 'dispose_example.di.g.dart';
part 'dispose_example.g.dart';

/// Collects everything that was torn down.
///
/// Disposal is observed from the outside, because the provider that held the
/// instance is gone by the time it happens.
final disposed = <Object>[];

/// The common case: an instance method carries the annotation. It is torn off
/// as `ref.onDispose(instance.close)`, so it must have no required parameters.
@riverDi
class Connection {
  @disposeMethod
  void close() => disposed.add(this);
}

/// The annotated method may also be static, as long as it takes the instance as
/// its first positional parameter. Any further parameter has to be optional and
/// keeps its default, as the generated closure only passes the instance.
@riverDi
class Session {
  final Connection connection;

  new(this.connection);

  @disposeMethod
  static void end(Session session, [int code = 42]) {
    disposed
      ..add(session)
      ..add(code);
  }
}

/// A class that cannot hold the annotation itself — here a `const` class with
/// no body — names its teardown on `@RiverDi` instead. The shape rules are the
/// same as for a static `@disposeMethod`.
@RiverDi(onDispose: _closeCache)
class const Cache();

void _closeCache(Cache cache) => disposed.add(cache);

/// `onDispose` also accepts a static method, of this or of any other class.
@RiverDi(onDispose: Registry.unregister)
class Registry {
  static void unregister(Registry registry) => disposed.add(registry);
}

/// Async providers register the awaited instance, not the future.
@riverDiAsync
class Worker {
  const new _();

  @providerConstructor
  static Future<Worker> spawn() async => const Worker._();

  @disposeMethod
  void stop() => disposed.add(this);
}

/// A `keepAlive` provider survives until its container goes away, and is
/// disposed together with it.
@riverDiSingleton
class Pool {
  @disposeMethod
  void drain() => disposed.add(this);
}
