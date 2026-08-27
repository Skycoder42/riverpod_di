// ignore_for_file: avoid_unused_constructor_parameters for example

import 'package:riverpod_di/riverpod_di.dart';

@riverDi
class const TestSimple();

@riverDi
class const TestReferring1(TestSimple simple);
