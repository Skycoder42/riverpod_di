import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';

const disposeMethod = DisposeMethod();

@immutable
@Target({.method})
class const DisposeMethod();
