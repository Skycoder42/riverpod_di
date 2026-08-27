// ignore_for_file: avoid_unused_constructor_parameters for example

import 'package:riverpod_injected/riverpod_injected.dart';

@riverDi
class const TestSimple();

@riverDi
class const TestReferring1(TestSimple simple);
