// Dependencies living in a different library.
//
// Nothing special is needed: the generated part references the provider by the
// name it will have, and importing the declaring library brings that name into
// scope.

import 'package:riverpod_di/riverpod_di.dart';

import 'cross_library_deps.dart';

part 'cross_library_example.di.g.dart';
part 'cross_library_example.g.dart';

/// [Logger] is a synchronous `@riverDi` class from the other library,
/// [RemoteClock] an asynchronous one, and [ticks] a hand-written provider.
@riverDiAsync
class const Scheduler(
  final Logger logger,
  final RemoteClock clock,
  @From.async(ticks) final int tick,
);

/// Chaining once more, this time across the library boundary in both
/// directions.
@riverDiAsyncSingleton
class const Supervisor(final Scheduler scheduler, final Logger logger);
