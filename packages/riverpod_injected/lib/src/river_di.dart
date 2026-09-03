/// @docImport 'package:riverpod_annotation/experimental/scope.dart';
library;

import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'dispose_method.dart';
import 'from.dart';
import 'provider_constructor.dart';

/// Generates an auto disposed, synchronous provider for the annotated class.
///
/// Shorthand for `@RiverDi()`.
const riverDi = RiverDi();

/// Generates a `keepAlive`, synchronous provider for the annotated class.
///
/// Shorthand for `@RiverDi(keepAlive: true)`.
const riverDiSingleton = RiverDi(keepAlive: true);

/// Generates an auto disposed, asynchronous provider for the annotated class.
///
/// Shorthand for `@RiverDi(async: true)`.
const riverDiAsync = RiverDi(async: true);

/// Generates a `keepAlive`, asynchronous provider for the annotated class.
///
/// Shorthand for `@RiverDi(keepAlive: true, async: true)`.
const riverDiAsyncSingleton = RiverDi(keepAlive: true, async: true);

/// Generates a riverpod provider that creates instances of the annotated class.
///
/// The generated provider function is named after the class and carries a
/// [Riverpod] annotation, generated from [name], [keepAlive], [retry] and
/// [dependencies], so `riverpod_generator` turns it into a provider the
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
class const RiverDi({
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

  /// The name of the generated provider.
  ///
  /// If null, the name will be derived from the annotated element,
  /// after applying prefix/suffix transformations from the `build.yaml`
  /// configuration.
  ///
  /// If non-null, transformation from the `build.yaml` will not be applied,
  /// and the name will be used as-is.
  ///
  /// This name should be unique within the library.
  final String? name,

  /// The default retry logic used by providers associated to this container.
  ///
  /// The default implementation:
  /// - has unlimited retries
  /// - starts with a delay of 200ms
  /// - doubles the delay on each retry up to 6.4 seconds
  /// - retries all failures
  final Duration? Function(int retryCount, Object error)? retry,

  /// Whether the state of the provider should be maintained if it is no-longer
  /// used.
  ///
  /// Defaults to false.
  final bool keepAlive = false,

  /// The list of providers that this provider potentially depends on.
  ///
  /// This list must contains the classes/functions annotated with `@riverpod`,
  /// not the generated providers themselves.
  ///
  /// Specifying this list is strictly equivalent to saying "This provider may
  /// be scoped". If a provider is scoped, it should specify [dependencies].
  /// If it is never scoped, it should not specify [dependencies].
  ///
  /// The content of [dependencies] should be a list of all the providers that
  /// this provider may depend on which can be scoped.
  ///
  /// For example, consider the following providers:
  /// ```dart
  /// // By not specifying "dependencies", we are saying that this provider is never scoped
  /// @riverpod
  /// Foo root(Ref ref) => Foo();
  ///
  /// // By specifying "dependencies" (even if the list is empty),
  /// // we are saying that this provider is potentially scoped
  /// @Riverpod(dependencies: [])
  /// Foo scoped(Ref ref) => Foo();
  ///
  /// // Alternatively, notifiers with an abstract build method are also considered scoped
  /// @riverpod
  /// class MyNotifier extends _$MyNotifier {
  ///  @override
  ///  int build();
  /// }
  /// ```
  ///
  /// Then if we were to depend on `rootProvider` in a scoped provider, we
  /// could write any of:
  ///
  /// ```dart
  /// @riverpod
  /// Object? dependent(Ref ref) {
  ///   ref.watch(rootProvider);
  ///   // This provider does not depend on any scoped provider,
  ///   // as such "dependencies" is optional
  /// }
  ///
  /// @Riverpod(dependencies: [])
  /// Object? dependent(Ref ref) {
  ///   ref.watch(rootProvider);
  ///   // This provider decided to specify "dependencies" anyway, marking
  ///   // "dependentProvider" as possibly scoped.
  ///   // Since "rootProvider" is never scoped, it doesn't need to be included
  ///   // in "dependencies".
  /// }
  ///
  /// @Riverpod(dependencies: [root])
  /// Object? dependent(Ref ref) {
  ///   ref.watch(rootProvider);
  ///   // Including "rootProvider" in "dependencies" is fine too, even though
  ///   // it is not required. It is a no-op.
  /// }
  /// ```
  ///
  /// However, if we were to depend on `scopedProvider` then our only choice is:
  ///
  /// ```dart
  /// @Riverpod(dependencies: [scoped])
  /// Object? dependent(Ref ref) {
  ///   ref.watch(scopedProvider);
  ///   // Since "scopedProvider" specifies "dependencies", any provider that
  ///   // depends on it must also specify "dependencies" and include "scopedProvider".
  /// }
  /// ```
  ///
  /// In that scenario, the `dependencies` parameter is required and it must
  /// include `scopedProvider`.
  ///
  /// **Note**:
  /// It is not necessary to specify an empty "dependencies" on notifiers with
  /// an abstract build method:
  /// ```dart
  /// @riverpod
  /// class MyNotifier extends _$MyNotifier {
  ///   @override
  ///   int build(); // Valid, marks this notifier as scoped
  /// }
  /// ```
  ///
  /// See also:
  /// - [Dependencies], for specifying dependencies on non-providers.
  /// - [provider_dependencies](https://github.com/rrousselGit/riverpod/tree/master/packages/riverpod_lint#provider_dependencies-riverpod_generator-only)
  ///   and [scoped_providers_should_specify_dependencies](https://github.com/rrousselGit/riverpod/tree/master/packages/riverpod_lint#scoped_providers_should_specify_dependencies-generator-only).\
  ///   These are lint rules that will warn about incorrect `dependencies`
  ///   usages.
  final List<Object>? dependencies,
});
