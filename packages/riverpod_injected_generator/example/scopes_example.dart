import 'package:riverpod_injected/riverpod_injected.dart';

part 'scopes_example.di.g.dart';
part 'scopes_example.g.dart';

@Riverpod(dependencies: [])
bool existingScoped(Ref _) => true;

@Riverpod(dependencies: [existingScoped])
class ScopedNotifier extends _$ScopedNotifier {
  @override
  int build() => 0;
}

@RiverDi(dependencies: [])
class ScopedType;

@RiverDi(dependencies: [ScopedType])
class ScopedDependency;

@RiverDi(dependencies: [ScopedType, existingScoped])
class DoubleScoped;

@RiverDi(dependencies: [DoubleScoped, ScopedNotifier])
class CombinedScoped;
