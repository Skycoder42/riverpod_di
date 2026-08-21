import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

const riverDi = RiverDi(riverpod);

const riverDiSingleton = RiverDi(Riverpod(keepAlive: true));

@immutable
@Target({.classType})
class const RiverDi(final Riverpod annotation);
