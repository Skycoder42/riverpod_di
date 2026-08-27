// Asynchronous dependency chains, the reason @riverDi exists.
//
// An async dependency is awaited for you: the generated provider watches
// `.future` and awaits it before the constructor is invoked.

import 'package:riverpod_injected/riverpod_injected.dart';

part 'async_chain_example.di.g.dart';
part 'async_chain_example.g.dart';

/// The synchronous root of the chain.
@riverDi
class const Config() {
  String get url => 'https://example.invalid';
}

/// Connecting takes time, so the instance is built by a [providerConstructor]
/// returning a [Future].
@riverDiAsync
class Database {
  final Config config;

  const new _(this.config);

  @providerConstructor
  static Future<Database> connect(Config config) async => Database._(config);
}

/// Async depending on async. [Database] is resolved and awaited automatically,
/// [Config] is watched synchronously.
@riverDiAsync
class const Repository(final Database database, final Config config);

/// An async annotation over a fully synchronous constructor is allowed; the
/// generated provider simply never awaits anything.
@riverDiAsync
class const Metrics(final Config config);

/// Naming a provider explicitly states the whole reference, so reaching for an
/// async one takes [From.async] — plain [From] would hand over the raw
/// `AsyncValue`.
@riverDiAsyncSingleton
class const Service(
  final Repository repository,
  @From.async(Database, read: true) final Database database,
);
