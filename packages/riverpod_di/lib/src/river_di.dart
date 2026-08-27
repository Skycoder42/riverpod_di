import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'dispose_method.dart';
import 'from.dart';
import 'provider_constructor.dart';

/// Generates an auto disposed, synchronous provider for the annotated class.
///
/// Shorthand for `@RiverDi(riverpod)`.
const riverDi = RiverDi(riverpod);

/// Generates a `keepAlive`, synchronous provider for the annotated class.
///
/// Shorthand for `@RiverDi(Riverpod(keepAlive: true))`.
const riverDiSingleton = RiverDi(Riverpod(keepAlive: true));

/// Generates an auto disposed, asynchronous provider for the annotated class.
///
/// Shorthand for `@RiverDi(riverpod, async: true)`.
const riverDiAsync = RiverDi(riverpod, async: true);

/// Generates a `keepAlive`, asynchronous provider for the annotated class.
///
/// Shorthand for `@RiverDi(Riverpod(keepAlive: true), async: true)`.
const riverDiAsyncSingleton = RiverDi(Riverpod(keepAlive: true), async: true);

/// Generates a riverpod provider that creates instances of the annotated class.
///
/// The generated provider function is named after the class and carries the
/// given [annotation], so `riverpod_generator` turns it into a provider the
/// same way it would for a hand written one. All parameters of the invoked
/// constructor are injected by watching the provider of their declared type,
/// unless they are annotated with [From] or have a default value. A [Ref]
/// parameter is handed the provider's own ref.
///
/// By default, the primary or unnamed constructor is invoked. Annotate a
/// different constructor or a static factory method with [ProviderConstructor]
/// to use that one instead.
///
/// ```dart
/// @RiverDi(Riverpod(keepAlive: true))
/// class const Repository(final Database database);
/// ```
///
/// For the common cases, use the [riverDi], [riverDiSingleton], [riverDiAsync]
/// and [riverDiAsyncSingleton] shorthands instead.
@immutable
@Target({.classType})
// ignore: public_member_api_docs false positive for primary constructors
class const RiverDi(
  /// The riverpod annotation to put on the generated provider function.
  ///
  /// Forwarded verbatim, which is how `keepAlive`, `name`, `dependencies` and
  /// `retry` are configured.
  final Riverpod annotation, {

  /// Whether the generated provider is asynchronous.
  ///
  /// Required if the invoked constructor returns a `Future` or `FutureOr` of
  /// the class, or if any parameter is injected from an asynchronous provider.
  final bool async = false,

  /// A function to invoke when the generated provider is disposed.
  ///
  /// Must accept the created instance as its only required positional
  /// parameter. Cannot be combined with a [DisposeMethod] annotated method.
  final Function? onDispose,
});
