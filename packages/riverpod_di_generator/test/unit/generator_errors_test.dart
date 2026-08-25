import 'package:dart_test_tools/test.dart';
import 'package:test/test.dart';

import 'builder_harness.dart';

typedef _Case = ({String name, String source, String message});

void main() {
  late BuilderHarness harness;

  setUpAll(() async => harness = await BuilderHarness.create());

  testData<_Case>(
    'reports a source error',
    const <_Case>[
      (
        name: 'multiple annotated provider constructors',
        source: '''
@riverDi
class Multi {
  const new _();

  @providerConstructor
  static Multi one() => const Multi._();

  @providerConstructor
  static Multi two() => const Multi._();
}
''',
        message:
            'Multiple constructors or methods are annotated with '
            'ProviderConstructor. Only a single one can be.',
      ),
      (
        name: 'no primary or unnamed constructor',
        source: '''
@riverDi
class Only {
  const new named();
}
''',
        message: 'Class has no primary or unnamed constructor!',
      ),
      (
        name: 'a non static method cannot be a provider constructor',
        source: '''
@riverDi
class Instance {
  const new _();

  @providerConstructor
  Instance make() => const Instance._();
}
''',
        message:
            'Only constructors and static methods can be annotated with '
            'ProviderConstructor.',
      ),
      (
        name: 'a provider constructor must return the enclosing type',
        source: '''
@riverDi
class Wrong {
  const new _();

  @providerConstructor
  static int make() => 42;
}
''',
        message:
            'A ProviderConstructor annotated method must return Wrong or a '
            'Future of it.',
      ),
      (
        name: 'a Future returning constructor needs the async annotation',
        source: '''
@riverDi
class NotAsync {
  const new _();

  @providerConstructor
  static Future<NotAsync> load() async => const NotAsync._();
}
''',
        message:
            'Constructor returns Future or FutureOr, but is not marked as '
            'async!',
      ),
      (
        name: 'an async dependency needs an async annotation',
        source: '''
@riverpod
Future<int> slow(Ref ref) async => 42;

@riverDi
class const Sync(@From.async(slow) final int value);
''',
        message:
            'Referenced provider is async, but the annotated class is not!',
      ),
      // NOTE: 'Cannot automatically inject family providers!' has no case here
      // because the check never runs. ProviderResolver._resolveRiverpod asks
      // for an unresolved AST node, so `astNode.provider` is always null and it
      // falls back to guessing the provider name before reaching the family
      // check. Injecting a family currently emits `ref.watch(theFamily)`, which
      // does not compile. Passing `resolve: true` to `astNodeFor` makes the
      // check fire; it leaves the output of every example unchanged, but costs
      // a full resolve of each referenced library.
      (
        name: 'a defaulted positional followed by an injected one',
        source: '''
@riverpod
int seed(Ref ref) => 42;

@riverDi
class Gap {
  new([int count = 1, @From(seed) int other = 2]);
}
''',
        message:
            'Positional parameter has a default value, but a later positional '
            'parameter is still injected.',
      ),
      (
        name: 'a dependency entry that is not a provider',
        source: '''
@RiverDi(Riverpod(dependencies: ['not a provider']))
class const Bad();
''',
        message: 'into a provider reference.',
      ),
    ],
    (data) async {
      final result = await harness.generate(data.source);

      expect(result.output, isNull);
      expect(result.errors, hasLength(1));
      expect(result.errors.single, contains(data.message));
    },
    dataToString: (data) => data.name,
  );
}
