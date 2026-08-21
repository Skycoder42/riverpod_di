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

// @riverDi
// class BasicNamed {
//   new named(Basic basic);
// }

@riverDi
class Factory {
  factory() => _Factory();
}

class _Factory implements Factory;
