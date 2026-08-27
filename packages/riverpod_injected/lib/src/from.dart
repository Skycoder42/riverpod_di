import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'river_di.dart';

/// Explicitly states the provider a constructor parameter is injected from.
///
/// Without this annotation, the provider is derived from the declared type of
/// the parameter. Naming it is required whenever that derivation cannot work
/// or would pick the wrong provider, i.e. if the parameter is typed as an
/// abstraction, if it refers to a provider that is not generated from a
/// [RiverDi] annotated class, or if it has a default value and would otherwise
/// be left to that default.
///
/// ```dart
/// @riverDi
/// class const Welcome(@From(friendlyGreeter) final Greeter greeter);
/// ```
@immutable
@Target({.parameter})
class From {
  /// The provider the parameter is injected from.
  ///
  /// Must be one of:
  /// - the [Type] of a class annotated with [RiverDi] or [Riverpod]
  /// - a function annotated with [Riverpod]
  /// - a [String] holding the name of the generated provider variable
  final dynamic provider;

  /// Whether the notifier itself is injected instead of the built value.
  ///
  /// See [From.notifier].
  final bool notifier;

  /// Whether the provider is asynchronous and has to be awaited.
  ///
  /// See [From.async].
  final bool async;

  /// Whether the provider is read once instead of being watched.
  ///
  /// If `true`, `ref.read` is used instead of `ref.watch` and the annotated
  /// class is thus not rebuilt when the referenced provider changes.
  final bool read;

  /// Injects the value of [provider].
  ///
  /// If [read] is `true`, the provider is read once instead of watched.
  const new(this.provider, {this.read = false})
    : notifier = false,
      async = false,
      assert(
        provider is Type || provider is Function || provider is String,
        'provider must be a provider annotated class type or function, '
        'or a provider name in form of a string.',
      );

  /// Injects the notifier of [provider] instead of the value it builds.
  ///
  /// [provider] must be the [Type] of a [Riverpod] annotated notifier class.
  /// The parameter is resolved as `provider.notifier`.
  ///
  /// If [read] is `true`, the provider is read once instead of watched.
  const new notifier(Type this.provider, {this.read = false})
    : notifier = true,
      async = false;

  /// Injects the awaited value of the asynchronous [provider].
  ///
  /// The parameter is resolved as `await provider.future`, which requires the
  /// annotated class to be asynchronous itself, i.e. annotated with
  /// [riverDiAsync], [riverDiAsyncSingleton] or `@RiverDi(..., async: true)`.
  ///
  /// If [read] is `true`, the provider is read once instead of watched.
  const new async(this.provider, {this.read = false})
    : notifier = false,
      async = true;
}
