import 'package:meta/meta.dart';
import 'package:meta/meta_meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

const riverDi = RiverDi(riverpod);

const riverDiSingleton = RiverDi(Riverpod(keepAlive: true));

const riverDiAsync = RiverDi(riverpod, async: true);

const riverDiAsyncSingleton = RiverDi(Riverpod(keepAlive: true), async: true);

@immutable
@Target({.classType})
class const RiverDi(final Riverpod annotation, {final bool async = false});
