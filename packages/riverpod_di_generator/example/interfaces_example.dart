// Injecting an abstraction: the implementation is named explicitly, nothing is
// inferred from the interface.

import 'package:riverpod_di/riverpod_di.dart';

part 'interfaces_example.di.g.dart';
part 'interfaces_example.g.dart';

/// The abstraction consumers depend on. It carries no annotation of its own and
/// therefore has no provider.
abstract interface class Greeter {
  String greet(String name);
}

@riverDi
class const FriendlyGreeter() implements Greeter {
  @override
  String greet(String name) => 'Hello, $name!';
}

@riverDi
class const TerseGreeter() implements Greeter {
  @override
  String greet(String name) => 'Hi $name';
}

/// Two implementations exist, so the choice has to be stated. Auto-resolution
/// works off the declared parameter type and would look for a `greeterProvider`
/// that does not exist.
@riverDi
class const Welcome(@From(FriendlyGreeter) final Greeter greeter) {
  String call(String name) => greeter.greet(name);
}

/// The same abstraction, wired to the other implementation.
@riverDi
class const Notification(@From(TerseGreeter) final Greeter greeter) {
  String call(String name) => greeter.greet(name);
}
