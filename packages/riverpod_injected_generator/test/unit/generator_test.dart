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
@RiverDi(name: 'renamed')
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

@RiverDi(keepAlive: true, retry: retryOnce, dependencies: [seed])
class const Scoped(@From(seed) final int value);
''',
        expected: '''
@Riverpod(keepAlive: true, retry: retryOnce, dependencies: [seed])
Scoped scoped(Ref ref) => Scoped(ref.watch(seedProvider));''',
      ),
      (
        name: 'a non provider dependency entry is forwarded verbatim',
        source: '''
@RiverDi(dependencies: ['not a provider'])
class const Bad();
''',
        expected: '''
@Riverpod(dependencies: ['not a provider'])
Bad bad(Ref ref) => const Bad();''',
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
      (
        name: 'an annotated instance method is torn off as the dispose hook',
        source: '''
@riverDi
class Connection {
  @disposeMethod
  void close() {}
}
''',
        expected: r'''
@Riverpod()
Connection connection(Ref ref) {
  final $instance = Connection();
  ref.onDispose($instance.close);
  return $instance;
}''',
      ),
      (
        name: 'an instance dispose method may have optional parameters',
        source: '''
@riverDi
class Connection {
  @disposeMethod
  void close([int retries = 3]) {}
}
''',
        expected: r'''
@Riverpod()
Connection connection(Ref ref) {
  final $instance = Connection();
  ref.onDispose($instance.close);
  return $instance;
}''',
      ),
      (
        name: 'an async instance dispose method is torn off unchanged',
        source: '''
@riverDi
class Connection {
  @disposeMethod
  Future<void> close() async {}
}
''',
        expected: r'''
@Riverpod()
Connection connection(Ref ref) {
  final $instance = Connection();
  ref.onDispose($instance.close);
  return $instance;
}''',
      ),
      (
        name: 'an annotated static method is handed the instance',
        source: '''
@riverDi
class Session {
  @disposeMethod
  static void end(Session session) {}
}
''',
        expected: r'''
@Riverpod()
Session session(Ref ref) {
  final $instance = Session();
  ref.onDispose(() => Session.end($instance));
  return $instance;
}''',
      ),
      (
        name: 'a static dispose method may have further optional parameters',
        source: '''
@riverDi
class Session {
  @disposeMethod
  static void end(Session session, [int code = 0]) {}
}
''',
        expected: r'''
@Riverpod()
Session session(Ref ref) {
  final $instance = Session();
  ref.onDispose(() => Session.end($instance));
  return $instance;
}''',
      ),
      (
        name: 'a static dispose method may take a supertype of the instance',
        source: '''
abstract interface class Closeable {}

@riverDi
class Session implements Closeable {
  @disposeMethod
  static void end(Closeable closeable) {}
}
''',
        expected: r'''
@Riverpod()
Session session(Ref ref) {
  final $instance = Session();
  ref.onDispose(() => Session.end($instance));
  return $instance;
}''',
      ),
      (
        name: 'onDispose accepts a top level function',
        source: '''
void _close(Cache cache) {}

@RiverDi(onDispose: _close)
class const Cache();
''',
        expected: r'''
@Riverpod()
Cache cache(Ref ref) {
  const $instance = Cache();
  ref.onDispose(() => _close($instance));
  return $instance;
}''',
      ),
      (
        name: 'onDispose accepts a static method of another class',
        source: '''
class Registry {
  static void unregister(Cache cache) {}
}

@RiverDi(onDispose: Registry.unregister)
class const Cache();
''',
        expected: r'''
@Riverpod()
Cache cache(Ref ref) {
  const $instance = Cache();
  ref.onDispose(() => Registry.unregister($instance));
  return $instance;
}''',
      ),
      (
        name: 'a dispose hook combines with the forwarded Riverpod annotation',
        source: '''
void _close(Cache cache) {}

@RiverDi(keepAlive: true, name: 'kept', onDispose: _close)
class const Cache();
''',
        expected: r'''
@Riverpod(keepAlive: true, name: 'kept')
Cache cache(Ref ref) {
  const $instance = Cache();
  ref.onDispose(() => _close($instance));
  return $instance;
}''',
      ),
      (
        name: 'dependencies are injected into the instance that is disposed',
        source: '''
@riverDi
class const Leaf();

@riverDi
class Owner {
  new(Leaf leaf);

  @disposeMethod
  void dispose() {}
}
''',
        expected: r'''
@Riverpod()
Leaf leaf(Ref ref) => const Leaf();

@Riverpod()
Owner owner(Ref ref) {
  final $instance = Owner(ref.watch(leafProvider));
  ref.onDispose($instance.dispose);
  return $instance;
}''',
      ),
      (
        name: 'an async provider registers the awaited instance',
        source: '''
@riverDiAsync
class Worker {
  const new _();

  @providerConstructor
  static Future<Worker> spawn() async => const Worker._();

  @disposeMethod
  void stop() {}
}
''',
        expected: r'''
@Riverpod()
FutureOr<Worker> worker(Ref ref) async {
  final $instance = await Worker.spawn();
  ref.onDispose($instance.stop);
  return $instance;
}''',
      ),
      (
        name: 'an unannotated method is not treated as a dispose hook',
        source: '''
@riverDi
class const Plain() {
  void dispose() {}

  static void close(Plain plain) {}
}
''',
        expected: '''
@Riverpod()
Plain plain(Ref ref) => const Plain();''',
      ),
      (
        name: 'an inherited dispose method is not picked up',
        source: '''
class Base {
  @disposeMethod
  void dispose() {}
}

@riverDi
class Derived extends Base;
''',
        expected: '''
@Riverpod()
Derived derived(Ref ref) => Derived();''',
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
