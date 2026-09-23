import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_partner/view/layout/order/controller/partner_orders_controller.dart';
import 'package:go_partner/view/layout/order/model/partner_order.dart';
import 'package:go_partner/view/layout/order/service/partner_orders_repository.dart';

import 'support/partner_orders_fixtures.dart';

class DelayedOrdersRepository extends MemoryOrdersRepository {
  Completer<void>? readGate;

  @override
  Future<PartnerOrderPage> services({bool history = false}) async {
    final snapshot = await super.services(history: history);
    final gate = readGate;
    if (gate != null) await gate.future;
    return snapshot;
  }
}

void main() {
  for (final professional in [false, true]) {
    testWidgets(
      '${professional ? 'service' : 'courier'} inbox updates without a refresh gesture',
      (tester) async {
        final repository = MemoryOrdersRepository();
        final controller = PartnerOrdersController(
          isProfessional: professional,
          repository: repository,
        );
        try {
          controller.startLiveUpdates();
          await tester.pump();
          expect(controller.initialized, isTrue);
          expect(controller.incoming, isEmpty);

          repository.items.add(
            professional
                ? serviceOrder(1, 'pending')
                : deliveryOrder(1, 'pending'),
          );
          await tester.pump(PartnerOrdersController.liveRefreshInterval);
          expect(controller.incoming.single.id, 1);

          repository.items[0] = professional
              ? serviceOrder(1, 'accepted')
              : deliveryOrder(1, 'accepted');
          controller.requestLiveRefresh();
          await tester.pump();
          expect(controller.incoming, isEmpty);
          expect(controller.active.single.id, 1);

          controller.pauseLiveUpdates();
          final reads = repository.reads.length;
          repository.items.clear();
          controller.requestLiveRefresh();
          await tester.pump(const Duration(minutes: 1));
          expect(repository.reads.length, reads);

          controller.startLiveUpdates();
          await tester.pump();
          expect(controller.active, isEmpty);
        } finally {
          controller.dispose();
        }
        final reads = repository.reads.length;
        await tester.pump(const Duration(minutes: 1));
        expect(repository.reads.length, reads);
      },
    );
  }

  testWidgets('failed automatic reads recover without tapping retry', (
    tester,
  ) async {
    final repository = MemoryOrdersRepository()
      ..items.add(serviceOrder(1, 'pending'));
    final controller = PartnerOrdersController(
      isProfessional: true,
      repository: repository,
    );
    try {
      controller.startLiveUpdates();
      await tester.pump();
      repository.failServices = true;
      await tester.pump(PartnerOrdersController.liveRefreshInterval);
      expect(controller.errors, isNotEmpty);
      expect(controller.incoming.single.id, 1);

      repository.failServices = false;
      repository.items.add(serviceOrder(2, 'pending'));
      await tester.pump(PartnerOrdersController.liveRefreshInterval);
      expect(controller.errors, isEmpty);
      expect(controller.incoming.map((order) => order.id), [1, 2]);
    } finally {
      controller.dispose();
    }
  });

  testWidgets('bursts during a slow read are coalesced but never lost', (
    tester,
  ) async {
    final repository = DelayedOrdersRepository();
    final controller = PartnerOrdersController(
      isProfessional: true,
      repository: repository,
    );
    final gate = Completer<void>();
    try {
      controller.startLiveUpdates();
      await tester.pump();
      repository.readGate = gate;
      controller.requestLiveRefresh();
      await tester.pump();
      final reads = repository.reads.length;

      repository.items.add(serviceOrder(2, 'pending'));
      for (var i = 0; i < 5; i++) {
        controller.requestLiveRefresh();
      }
      await tester.pump(const Duration(minutes: 1));
      expect(repository.reads.length, reads);

      repository.readGate = null;
      gate.complete();
      await tester.pump();
      expect(repository.reads.length, reads + 1);
      expect(controller.incoming.single.id, 2);
    } finally {
      if (!gate.isCompleted) gate.complete();
      controller.dispose();
    }
  });

  test(
    'events received during a rejected write still refresh the inbox',
    () async {
      final repository = MemoryOrdersRepository()
        ..items.add(serviceOrder(1, 'pending'))
        ..failWrite = true
        ..writeGate = Completer<void>();
      final controller = PartnerOrdersController(
        isProfessional: true,
        repository: repository,
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      final action = controller.act(
        controller.incoming.single,
        PartnerOrderAction.accept,
      );
      final rejected = expectLater(
        action,
        throwsA(isA<PartnerOrdersException>()),
      );
      repository.items.add(serviceOrder(2, 'pending'));
      await controller.refresh();
      repository.writeGate!.complete();
      await rejected;
      expect(controller.incoming.map((order) => order.id), [1, 2]);
    },
  );
}
