/// @docImport 'dart:async';
library;

import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

import 'river_di.dart';

/// Marks a constructor or static method as the one to create instances with.
///
/// Shorthand for [ProviderConstructor].
const providerConstructor = ProviderConstructor();

/// Marks a constructor or static method as the one the generated provider
/// creates instances with.
///
/// Without this annotation, the primary or unnamed constructor of the [RiverDi]
/// annotated class is invoked. Only a single constructor or method per class
/// can carry it.
///
/// An annotated method must be static and return the class or a [Future] or
/// [FutureOr] of it. Returning asynchronously requires the class to be
/// annotated as asynchronous.
///
/// ```dart
/// @riverDiAsync
/// class Database {
///   const new _();
///
///   @providerConstructor
///   static Future<Database> connect() async => const Database._();
/// }
/// ```
@immutable
@Target({.constructor, .method})
// ignore: public_member_api_docs false positive for primary constructors
class const ProviderConstructor();
