// Reads every provider generated for the example libraries, to check that the
// generated code not only compiles but also resolves at runtime.
//
// Identity across an `await` is only asserted within a single resolved object
// graph. Comparing against a fresh `container.read` after an await would race
// the auto dispose of the provider in between.

import 'package:riverpod/misc.dart' show ProviderListenable;
import 'package:riverpod/riverpod.dart';
import 'package:test/test.dart';

import '../../example/async_chain_example.dart' as async_chain;
import '../../example/constructor_shapes_example.dart' as shapes;
import '../../example/cross_library_deps.dart' as deps;
import '../../example/cross_library_example.dart' as cross;
import '../../example/interfaces_example.dart' as interfaces;
import '../../example/naming_example.dart' as naming;
import '../../example/riverpod_di_generator_example.dart' as base;

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer.test(
      overrides: [naming.appVersionProvider.overrideWithValue('1.2.3')],
    );
  });

  /// Awaits an async provider while holding a subscription to it.
  ///
  /// `container.read(provider.future)` on its own creates no subscription, so
  /// an auto dispose provider can be torn down while still loading and its
  /// future then never completes.
  Future<T> awaitValue<T>(ProviderListenable<Future<T>> future) {
    final subscription = container.listen(future, (_, _) {});
    addTearDown(subscription.close);
    return subscription.read();
  }

  group('constructor selection', () {
    test('every constructor shape resolves', () {
      expect(container.read(base.testSimpleProvider), isNotNull);
      expect(container.read(base.testReferring1Provider), isNotNull);
      expect(container.read(base.testReferring2Provider), isNotNull);
      expect(container.read(base.basicProvider), isNotNull);
      expect(container.read(base.basicDefaultProvider), isNotNull);
      expect(container.read(base.basicNamedProvider), isNotNull);
      expect(container.read(base.factoryProvider), isNotNull);
      expect(container.read(base.fromMethodProvider), isNotNull);
      expect(container.read(base.competingProvider), isNotNull);
    });

    test('a dependency is the instance its own provider holds', () {
      expect(container.read(base.testReferring1Provider), isNotNull);
      expect(
        container.read(base.testSimpleProvider),
        same(container.read(base.testSimpleProvider)),
      );
    });

    test('async providers resolve', () async {
      await expectLater(awaitValue(base.fromFutureProvider.future), completes);
      await expectLater(
        awaitValue(base.fromFutureOrProvider.future),
        completes,
      );
      await expectLater(
        awaitValue(base.fromExternalProvider.future),
        completes,
      );
    });
  });

  group('async chain', () {
    test('every level resolves', () async {
      await expectLater(
        awaitValue(async_chain.databaseProvider.future),
        completes,
      );
      await expectLater(
        awaitValue(async_chain.repositoryProvider.future),
        completes,
      );
      await expectLater(
        awaitValue(async_chain.metricsProvider.future),
        completes,
      );
      await expectLater(
        awaitValue(async_chain.serviceProvider.future),
        completes,
      );
    });

    test('every level shares the instances below it', () async {
      final service = await awaitValue(async_chain.serviceProvider.future);

      expect(service.repository.database, same(service.database));
      expect(service.repository.config, same(service.database.config));
    });

    test('an async annotation over a sync constructor resolves', () async {
      final metrics = await awaitValue(async_chain.metricsProvider.future);

      expect(metrics.config, isNotNull);
    });
  });

  group('constructor shapes', () {
    test('field formals are injected', () {
      final car = container.read(shapes.carProvider);

      expect(car.engine, same(container.read(shapes.engineProvider)));
      expect(car.wheels, same(container.read(shapes.wheelsProvider)));
    });

    test('a super parameter is injected', () {
      final truck = container.read(shapes.truckProvider);

      expect(truck.engine, same(container.read(shapes.engineProvider)));
      expect(truck.wheels, same(container.read(shapes.wheelsProvider)));
    });

    test('an undefaulted optional positional is injected', () {
      final trailer = container.read(shapes.trailerProvider);

      expect(trailer.wheels, same(container.read(shapes.wheelsProvider)));
      expect(trailer.engine, same(container.read(shapes.engineProvider)));
    });

    test('a defaulted positional keeps its default', () {
      expect(container.read(shapes.trailerProvider).axles, 2);
    });

    test('an undefaulted optional named is injected', () {
      final garage = container.read(shapes.garageProvider);

      expect(garage.engine, same(container.read(shapes.engineProvider)));
      expect(garage.spare, same(container.read(shapes.wheelsProvider)));
    });

    test('a defaulted named keeps its default', () {
      expect(container.read(shapes.garageProvider).capacity, 10);
    });

    test('a defaulted parameter opts back in via From', () {
      final depot = container.read(shapes.depotProvider);

      expect(depot.engine, same(container.read(shapes.engineProvider)));
      expect(depot.wheels, const shapes.Wheels());
    });

    test('a Ref parameter is the ref of the generated provider', () {
      final ownContainer = ProviderContainer.test();
      final workshop = ownContainer.read(shapes.workshopProvider);

      expect(workshop.engine, isNotNull);
      expect(workshop.disposed, isFalse);

      ownContainer.dispose();

      expect(workshop.disposed, isTrue);
    });
  });

  group('interfaces', () {
    test('each consumer gets the implementation it named', () {
      expect(
        container.read(interfaces.welcomeProvider)('world'),
        'Hello, world!',
      );
      expect(
        container.read(interfaces.notificationProvider)('world'),
        'Hi world',
      );
    });

    test('the implementations come from their own providers', () {
      expect(
        container.read(interfaces.welcomeProvider).greeter,
        same(container.read(interfaces.friendlyGreeterProvider)),
      );
      expect(
        container.read(interfaces.notificationProvider).greeter,
        same(container.read(interfaces.terseGreeterProvider)),
      );
    });
  });

  group('naming', () {
    test('a stripped name resolves on both sides', () {
      expect(
        container.read(naming.settingsConsumerProvider).settings,
        same(container.read(naming.settingsProvider)),
      );
    });

    test('an explicit name resolves on both sides', () {
      expect(
        container.read(naming.clockConsumerProvider).clock,
        same(container.read(naming.clockProvider)),
      );
    });

    test('a keepAlive provider resolves', () {
      expect(
        container.read(naming.cacheProvider).clock,
        same(container.read(naming.clockProvider)),
      );
    });

    test('a scoped provider reads its overridden dependency', () {
      expect(container.read(naming.scopedProvider).version, '1.2.3');
    });
  });

  group('cross library', () {
    test('providers of the other library resolve', () async {
      expect(container.read(deps.loggerProvider), isNotNull);
      await expectLater(awaitValue(deps.remoteClockProvider.future), completes);
      await expectLater(awaitValue(cross.schedulerProvider.future), completes);
      await expectLater(awaitValue(cross.supervisorProvider.future), completes);
    });

    test('dependencies from the other library are shared', () async {
      final scheduler = await awaitValue(cross.schedulerProvider.future);

      expect(scheduler.logger, same(scheduler.clock.logger));
    });

    test('a stream provider is awaited to its first value', () async {
      final scheduler = await awaitValue(cross.schedulerProvider.future);

      expect(scheduler.tick, 1);
    });

    test('chaining continues across the library boundary', () async {
      final supervisor = await awaitValue(cross.supervisorProvider.future);

      expect(supervisor.logger, same(supervisor.scheduler.logger));
      expect(supervisor.logger, same(supervisor.scheduler.clock.logger));
    });
  });
}
