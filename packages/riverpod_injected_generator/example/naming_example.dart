// Provider name derivation, and forwarding the rest of the Riverpod annotation.
//
// Both sides of the chain derive the name the same way: the generated provider
// function is named after the class, and riverpod_generator then applies the
// prefix, suffix and strip pattern from build.yaml to that name.

import 'package:riverpod_injected/riverpod_injected.dart';

part 'naming_example.di.g.dart';
part 'naming_example.g.dart';

/// The default strip pattern drops a trailing `Notifier`, so this becomes
/// `settingsProvider` rather than `settingsNotifierProvider`.
@riverDi
class const SettingsNotifier();

/// Resolved against the stripped name, not the class name.
@riverDi
class const SettingsConsumer(final SettingsNotifier settings);

/// An explicit name wins over the derived one.
@RiverDi(Riverpod(name: 'clockProvider'))
class const Clock();

/// And consumers follow it.
@riverDi
class const ClockConsumer(final Clock clock);

/// `keepAlive`, via the singleton alias.
@riverDiSingleton
class const Cache(final Clock clock);

/// A scoped dependency, overridden by whoever creates the container.
@riverpod
String appVersion(Ref ref) =>
    throw UnimplementedError('appVersion must be overridden by the container');

Duration? _retryTwice(int retryCount, Object error) =>
    retryCount < 2 ? Duration.zero : null;

/// `retry` and `dependencies` are forwarded to the generated annotation
/// verbatim.
@RiverDi(
  Riverpod(keepAlive: true, retry: _retryTwice, dependencies: [appVersion]),
)
class const Scoped(@From(appVersion) final String version);
