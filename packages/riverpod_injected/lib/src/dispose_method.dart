import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

import 'river_di.dart';

/// Marks a method to be invoked when the generated provider is disposed.
///
/// Shorthand for [DisposeMethod].
const disposeMethod = DisposeMethod();

/// Marks a method of a [RiverDi] annotated class to be invoked when the
/// generated provider is disposed.
///
/// Only a single method per class can carry it, and it cannot be combined with
/// the `onDispose` parameter of [RiverDi].
///
/// An instance method must have no required parameters, as it is torn off the
/// created instance. A static method must accept the instance as its first
/// positional parameter and have no other required parameters.
///
/// ```dart
/// @riverDi
/// class Connection {
///   @disposeMethod
///   void close() {}
/// }
/// ```
@immutable
@Target({.method})
// ignore: public_member_api_docs false positive for primary constructors
class const DisposeMethod();
