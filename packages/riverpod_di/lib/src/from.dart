import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

@immutable
@Target({.parameter})
class From {
  final dynamic provider;
  final bool notifier;
  final bool async;
  final bool read;

  const new(this.provider, {this.read = false})
    : notifier = false,
      async = false,
      assert(
        provider is Type || provider is Function || provider is String,
        'provider must be a provider annotated class type or function, '
        'or a provider name in form of a string.',
      );

  const new notifier(Type this.provider, {this.read = false})
    : notifier = true,
      async = false;

  const new async(this.provider, {this.read = false})
    : notifier = false,
      async = true;
}
