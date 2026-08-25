// The other half of cross_library_example.dart. Providers declared here are
// resolved from there without any extra configuration.

import 'package:riverpod_di/riverpod_di.dart';

part 'cross_library_deps.di.g.dart';
part 'cross_library_deps.g.dart';

@riverDi
class const Logger() {
  void log(String message) {}
}

@riverDiAsync
class RemoteClock {
  final Logger logger;

  const new _(this.logger);

  @providerConstructor
  static Future<RemoteClock> connect(Logger logger) async =>
      RemoteClock._(logger);
}

/// A hand-written riverpod provider rather than a `@riverDi` class.
@riverpod
Stream<int> ticks(Ref ref) => Stream.fromIterable(const [1, 2, 3]);
