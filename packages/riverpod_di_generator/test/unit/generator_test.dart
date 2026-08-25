import 'package:dart_test_tools/test.dart';
import 'package:test/test.dart';

import 'builder_harness.dart';

typedef _Case = ({String name, String source, String expected});

void main() {
  late BuilderHarness harness;

  setUpAll(() async => harness = await BuilderHarness.create());

  testData<_Case>(
    'generates the expected provider',
    const <_Case>[
      (
        name: 'const class without dependencies',
        source: '''
@riverDi
class const Leaf();
''',
        expected: '''
@Riverpod()
Leaf leaf(Ref ref) => const Leaf();''',
      ),
      (
        name: 'watches a dependency',
        source: '''
@riverDi
class const Leaf();

@riverDi
class const Root(final Leaf leaf);
''',
        expected: '''
@Riverpod()
Leaf leaf(Ref ref) => const Leaf();

@Riverpod()
Root root(Ref ref) => Root(ref.watch(leafProvider));''',
      ),
      (
        name: 'named primary constructor',
        source: '''
@riverDi
class const Leaf();

@riverDi
class const Root.create(final Leaf leaf, {final Leaf? optional});
''',
        expected: '''
@Riverpod()
Leaf leaf(Ref ref) => const Leaf();

@Riverpod()
Root root(Ref ref) =>
    Root.create(ref.watch(leafProvider), optional: ref.watch(leafProvider));''',
      ),
      (
        name: 'providerConstructor selects a named constructor',
        source: '''
@riverDi
class Chosen {
  const new _();

  @providerConstructor
  const factory picked() = Chosen._;
}
''',
        expected: '''
@Riverpod()
Chosen chosen(Ref ref) => const Chosen.picked();''',
      ),
      (
        name: 'providerConstructor selects a static method',
        source: '''
@riverDi
class Built {
  const new _();

  @providerConstructor
  static Built make() => const Built._();
}
''',
        expected: '''
@Riverpod()
Built built(Ref ref) => Built.make();''',
      ),
      (
        name: 'unnamed factory constructor',
        source: '''
@riverDi
class Made {
  factory() => _Made();
}

class _Made implements Made;
''',
        expected: '''
@Riverpod()
Made made(Ref ref) => Made();''',
      ),
      (
        name: 'async via a Future returning method',
        source: '''
@riverDiAsync
class Loaded {
  const new _();

  @providerConstructor
  static Future<Loaded> load() async => const Loaded._();
}
''',
        expected: '''
@Riverpod()
FutureOr<Loaded> loaded(Ref ref) async => await Loaded.load();''',
      ),
      (
        name: 'async via a FutureOr returning method',
        source: '''
@riverDiAsync
class Loaded {
  const new _();

  @providerConstructor
  static FutureOr<Loaded> load() => const Loaded._();
}
''',
        expected: '''
@Riverpod()
FutureOr<Loaded> loaded(Ref ref) async => await Loaded.load();''',
      ),
      (
        name: 'async dependencies are awaited',
        source: '''
@riverDiAsync
class Slow {
  const new _();

  @providerConstructor
  static Future<Slow> load() async => const Slow._();
}

@riverDiAsync
class const Fast(final Slow slow);
''',
        expected: '''
@Riverpod()
FutureOr<Slow> slow(Ref ref) async => await Slow.load();

@Riverpod()
FutureOr<Fast> fast(Ref ref) async =>
    Fast(await ref.watch(slowProvider.future));''',
      ),
      (
        name: 'async annotation over a synchronous constructor',
        source: '''
@riverDi
class const Leaf();

@riverDiAsync
class const Eager(final Leaf leaf);
''',
        expected: '''
@Riverpod()
Leaf leaf(Ref ref) => const Leaf();

@Riverpod()
FutureOr<Eager> eager(Ref ref) async => Eager(ref.watch(leafProvider));''',
      ),
      (
        name: 'singleton alias sets keepAlive',
        source: '''
@riverDiSingleton
class const Kept();
''',
        expected: '''
@Riverpod(keepAlive: true)
Kept kept(Ref ref) => const Kept();''',
      ),
      (
        name: 'async singleton alias sets keepAlive',
        source: '''
@riverDiAsyncSingleton
class const Kept();
''',
        expected: '''
@Riverpod(keepAlive: true)
FutureOr<Kept> kept(Ref ref) async => const Kept();''',
      ),
      (
        name: 'explicit provider name is forwarded',
        source: '''
@RiverDi(Riverpod(name: 'renamed'))
class const Named();

@riverDi
class const Consumer(final Named named);
''',
        expected: '''
@Riverpod(name: 'renamed')
Named named(Ref ref) => const Named();

@Riverpod()
Consumer consumer(Ref ref) => Consumer(ref.watch(renamed));''',
      ),
      (
        name: 'dependencies and retry are forwarded',
        source: '''
@riverpod
int seed(Ref ref) => 42;

Duration? retryOnce(int count, Object error) => null;

@RiverDi(
  Riverpod(keepAlive: true, retry: retryOnce, dependencies: [seed]),
)
class const Scoped(@From(seed) final int value);
''',
        expected: '''
@Riverpod(keepAlive: true, dependencies: [seed], retry: retryOnce)
Scoped scoped(Ref ref) => Scoped(ref.watch(seedProvider));''',
      ),
      (
        name: 'the trailing Notifier suffix is stripped from both sides',
        source: '''
@riverDi
class const SettingsNotifier();

@riverDi
class const Consumer(final SettingsNotifier settings);
''',
        expected: '''
@Riverpod()
SettingsNotifier settingsNotifier(Ref ref) => const SettingsNotifier();

@Riverpod()
Consumer consumer(Ref ref) => Consumer(ref.watch(settingsProvider));''',
      ),
      (
        name: 'defaulted parameters keep their default',
        source: '''
@riverDi
class const Leaf();

@riverDi
class Defaults {
  new({Leaf? leaf, int count = 3});
}
''',
        expected: '''
@Riverpod()
Leaf leaf(Ref ref) => const Leaf();

@Riverpod()
Defaults defaults(Ref ref) => Defaults(leaf: ref.watch(leafProvider));''',
      ),
      (
        name: 'a defaulted parameter opts back in via From',
        source: '''
@riverpod
int seed(Ref ref) => 42;

@riverDi
class Opted {
  new({@From(seed) int count = 3});
}
''',
        expected: '''
@Riverpod()
Opted opted(Ref ref) => Opted(count: ref.watch(seedProvider));''',
      ),
      (
        name: 'a defaulted trailing positional is dropped',
        source: '''
@riverDi
class const Leaf();

@riverDi
class Trailing {
  new(Leaf leaf, [int count = 1]);
}
''',
        expected: '''
@Riverpod()
Leaf leaf(Ref ref) => const Leaf();

@Riverpod()
Trailing trailing(Ref ref) => Trailing(ref.watch(leafProvider));''',
      ),
      (
        name: 'dropping every argument still yields a const instance',
        source: '''
@riverDi
class const Defaulted([final int count = 1]);
''',
        expected: '''
@Riverpod()
Defaulted defaulted(Ref ref) => const Defaulted();''',
      ),
      (
        name: 'a Ref parameter is passed through',
        source: '''
@riverDi
class const Leaf();

@riverDi
class const Managed(final Ref ref, final Leaf leaf);
''',
        expected: '''
@Riverpod()
Leaf leaf(Ref ref) => const Leaf();

@Riverpod()
Managed managed(Ref ref) => Managed(ref, ref.watch(leafProvider));''',
      ),
      (
        name: 'field formals and super parameters',
        source: '''
@riverDi
class const Leaf();

class Base {
  final Leaf leaf;

  new(this.leaf);
}

@riverDi
class Derived extends Base {
  final Leaf other;

  new(this.other, super.leaf);
}
''',
        expected: '''
@Riverpod()
Leaf leaf(Ref ref) => const Leaf();

@Riverpod()
Derived derived(Ref ref) =>
    Derived(ref.watch(leafProvider), ref.watch(leafProvider));''',
      ),
      (
        name: 'From selects an implementation for an interface',
        source: '''
abstract interface class Api {}

@riverDi
class const ApiImpl() implements Api;

@riverDi
class const Consumer(@From(ApiImpl) final Api api);
''',
        expected: '''
@Riverpod()
ApiImpl apiImpl(Ref ref) => const ApiImpl();

@Riverpod()
Consumer consumer(Ref ref) => Consumer(ref.watch(apiImplProvider));''',
      ),
      (
        name: 'From accepts a provider name as a string',
        source: '''
@riverpod
int seed(Ref ref) => 42;

@riverDi
class const Consumer(@From('seedProvider') final int value);
''',
        expected: '''
@Riverpod()
Consumer consumer(Ref ref) => Consumer(ref.watch(seedProvider));''',
      ),
      (
        name: 'From reads instead of watching',
        source: '''
@riverpod
int seed(Ref ref) => 42;

@riverDi
class const Consumer(@From(seed, read: true) final int value);
''',
        expected: '''
@Riverpod()
Consumer consumer(Ref ref) => Consumer(ref.read(seedProvider));''',
      ),
      (
        name: 'From.async awaits the future of an external provider',
        source: '''
@riverpod
Future<int> slow(Ref ref) async => 42;

@riverDiAsync
class const Consumer(@From.async(slow, read: true) final int value);
''',
        expected: '''
@Riverpod()
FutureOr<Consumer> consumer(Ref ref) async =>
    Consumer(await ref.read(slowProvider.future));''',
      ),
      (
        name: 'From.async awaits a stream provider',
        source: '''
@riverpod
Stream<int> ticks(Ref ref) => Stream.value(1);

@riverDiAsync
class const Consumer(@From.async(ticks) final int value);
''',
        expected: '''
@Riverpod()
FutureOr<Consumer> consumer(Ref ref) async =>
    Consumer(await ref.watch(ticksProvider.future));''',
      ),
    ],
    (data) async {
      final result = await harness.generate(data.source);

      expect(result.errors, isEmpty);
      expect(result.output, data.expected);
    },
    dataToString: (data) => data.name,
  );
}
