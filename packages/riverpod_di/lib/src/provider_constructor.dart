import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

const providerConstructor = ProviderConstructor();

@immutable
@Target({.constructor, .method})
class const ProviderConstructor();
