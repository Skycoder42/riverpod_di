// Field formals, super parameters, optional and defaulted parameters, and the
// Ref itself.

import 'package:riverpod_di/riverpod_di.dart';

part 'constructor_shapes_example.di.g.dart';
part 'constructor_shapes_example.g.dart';

@riverDi
class const Engine();

@riverDi
class const Wheels();

/// Field formals are ordinary positional parameters as far as injection goes.
@riverDi
class Car {
  final Engine engine;
  final Wheels wheels;

  new(this.engine, this.wheels);
}

class Vehicle {
  final Engine engine;

  new(this.engine);
}

/// A `super.` parameter is forwarded like any other positional parameter.
@riverDi
class Truck extends Vehicle {
  final Wheels wheels;

  new(this.wheels, super.engine);
}

/// An optional positional parameter is injected while it has no default of its
/// own; [axles] keeps its default and is left out of the generated call.
@riverDi
class Trailer {
  final Wheels wheels;
  final Engine? engine;
  final int axles;

  new(this.wheels, [this.engine, this.axles = 2]);
}

/// The same rule for named parameters: [capacity] keeps its default, while
/// [spare] is optional but undefaulted and so still injected.
@riverDi
class Garage {
  final Engine engine;
  final Wheels? spare;
  final int capacity;

  new({required this.engine, this.spare, this.capacity = 10});
}

/// A defaulted parameter opts back in by naming its provider explicitly.
@riverDi
class Depot {
  final Wheels wheels;
  final Engine? engine;

  new({this.wheels = const Wheels(), @From(Engine) this.engine});
}

/// A [Ref] parameter is handed the provider's own ref, so a service can manage
/// its own lifecycle.
@riverDi
class Workshop {
  final Engine engine;

  var _disposed = false;

  bool get disposed => _disposed;

  new(Ref ref, this.engine) {
    ref.onDispose(() => _disposed = true);
  }
}
