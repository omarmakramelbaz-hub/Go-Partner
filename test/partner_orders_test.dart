import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_partner/helpers/networking/api_helper.dart';
import 'package:go_partner/helpers/networking/urls.dart';
import 'package:go_partner/view/layout/order/controller/partner_orders_controller.dart';
import 'package:go_partner/view/layout/order/model/partner_order.dart';
import 'package:go_partner/view/layout/order/service/partner_orders_repository.dart';

import 'support/partner_orders_fixtures.dart';

void main() {
  test(
    'courier inbox combines both sources without colliding IDs or hiding older active orders',
    () async {
      final repo = MemoryOrdersRepository()
        ..items.addAll([
          deliveryOrder(1, 'accepted'),
          serviceOrder(1, 'pending'),
          deliveryOrder(2, 'shipped'),
          serviceOrder(3, 'accepted'),
          serviceOrder(4, 'completed'),
        ]);
      final controller = PartnerOrdersController(
        isProfessional: false,
        repository: repo,
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      expect(controller.active.map((item) => item.key), [
        'delivery:1',
        'delivery:2',
        'service:3',
      ]);
      expect(controller.incoming.single.key, 'service:1');
      await controller.act(
        controller.incoming.single,
        PartnerOrderAction.accept,
      );
      expect(
        controller.active.map((item) => item.key),
        containsAll(['delivery:1', 'service:1']),
      );
      await controller.loadHistory();
      expect(controller.history.single.key, 'service:4');
    },
  );

  test(
    'professional accounts load their service inbox without requesting delivery work',
    () async {
      final repo = MemoryOrdersRepository()
        ..items.addAll([
          serviceOrder(1, 'pending'),
          deliveryOrder(2, 'pending'),
        ]);
      final controller = PartnerOrdersController(
        isProfessional: true,
        repository: repo,
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      expect(controller.incoming.single.key, 'service:1');
      expect(repo.reads, ['services']);
      await controller.act(
        controller.incoming.single,
        PartnerOrderAction.accept,
      );
      expect(controller.active.single.status, 'accepted');
      await controller.act(
        controller.active.single,
        PartnerOrderAction.complete,
      );
      expect(controller.active, isEmpty);
      await controller.loadHistory();
      expect(controller.history.single.status, 'completed');
      expect(repo.reads.any((read) => read.contains(':')), isFalse);
    },
  );

  test(
    'delivery acceptance awaiting the customer is not represented as assigned work',
    () async {
      final repo = MemoryOrdersRepository()
        ..shippingNeedsConfirmation = true
        ..items.add(deliveryOrder(10, 'pending'));
      final controller = PartnerOrdersController(
        isProfessional: false,
        repository: repo,
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      await controller.act(
        controller.incoming.single,
        PartnerOrderAction.accept,
      );
      expect(controller.incoming, isEmpty);
      final waiting = controller.active.single;
      expect(waiting.awaitingConfirmation, isTrue);
      expect(waiting.allows(PartnerOrderAction.pickup), isFalse);
      expect(waiting.allows(PartnerOrderAction.complete), isFalse);
      expect(waiting.statusLabel(true), 'بانتظار تأكيد العميل');
    },
  );

  test(
    'each courier stage is confirmed before progressing, and declines leave the inbox',
    () async {
      final repo = MemoryOrdersRepository()
        ..items.addAll([
          deliveryOrder(1, 'pending'),
          serviceOrder(2, 'pending'),
        ]);
      final controller = PartnerOrdersController(
        isProfessional: false,
        repository: repo,
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      await controller.act(
        controller.incoming.first,
        PartnerOrderAction.accept,
      );
      expect(
        await controller.act(
          controller.active.single,
          PartnerOrderAction.complete,
        ),
        isFalse,
      );
      await controller.act(controller.active.single, PartnerOrderAction.pickup);
      expect(controller.active.single.step, 1);
      await controller.act(
        controller.active.single,
        PartnerOrderAction.complete,
      );
      expect(controller.active, isEmpty);
      await controller.act(
        controller.incoming.single,
        PartnerOrderAction.decline,
      );
      expect(controller.incoming, isEmpty);
    },
  );

  test(
    'partial failure preserves known requests and does not block the healthy source',
    () async {
      final repo = MemoryOrdersRepository()
        ..items.addAll([
          serviceOrder(1, 'pending'),
          deliveryOrder(2, 'pending'),
        ]);
      final controller = PartnerOrdersController(
        isProfessional: false,
        repository: repo,
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      repo.failServices = true;
      await controller.refresh();
      expect(controller.incoming.length, 2);
      expect(controller.errors.containsKey(PartnerOrderFeed.services), isTrue);
      expect(
        await controller.act(
          controller.incoming.last,
          PartnerOrderAction.accept,
        ),
        isFalse,
      );
      expect(
        await controller.act(
          controller.incoming.first,
          PartnerOrderAction.accept,
        ),
        isTrue,
      );
      expect(controller.active.single.key, 'delivery:2');
      repo.failServices = false;
      await controller.refresh();
      expect(controller.errors, isEmpty);
    },
  );

  test(
    'failed writes keep the card actionable, and duplicate taps submit once',
    () async {
      final repo = MemoryOrdersRepository()
        ..items.add(serviceOrder(1, 'pending'))
        ..failWrite = true;
      final controller = PartnerOrdersController(
        isProfessional: true,
        repository: repo,
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      final order = controller.incoming.single;
      await expectLater(
        controller.act(order, PartnerOrderAction.accept),
        throwsA(isA<PartnerOrdersException>()),
      );
      expect(controller.incoming.single.key, order.key);
      expect(controller.busy(order), isFalse);
      repo.failWrite = false;
      repo.writeGate = Completer<void>();
      final action = controller.act(order, PartnerOrderAction.accept);
      expect(await controller.act(order, PartnerOrderAction.accept), isFalse);
      final reads = repo.reads.length;
      await controller.refresh();
      expect(repo.reads.length, reads);
      repo.writeGate!.complete();
      await action;
      expect(
        repo.writes.length,
        2,
      ); // one rejected write and one successful write
      expect(controller.active.single.key, order.key);
    },
  );

  test(
    'delivery pagination exposes all other requests without duplicating cards',
    () async {
      final repo = MemoryOrdersRepository()
        ..items.addAll(
          List.generate(8, (i) => deliveryOrder(i + 1, 'pending')),
        );
      final controller = PartnerOrdersController(
        isProfessional: false,
        repository: repo,
      );
      addTearDown(controller.dispose);
      await controller.refresh();
      expect(controller.incoming.length, 5);
      expect(controller.hasMoreNew, isTrue);
      await controller.loadMore(PartnerOrderFeed.deliveryNew);
      expect(controller.incoming.length, 8);
      expect(controller.hasMoreNew, isFalse);
      await controller.refresh();
      expect(controller.incoming.length, 8);
    },
  );

  test(
    'closing the screen during a request never notifies a disposed controller',
    () async {
      final gate = Completer<ApiResponse>();
      final repository = PartnerOrdersRepository(
        get: (url, {queryParameters}) => gate.future,
      );
      final controller = PartnerOrdersController(
        isProfessional: true,
        repository: repository,
      );
      final load = controller.refresh();
      controller.dispose();
      gate.complete(
        ApiResponse(state: ResponseState.complete, data: {'data': []}),
      );
      await load;
    },
  );

  test(
    'repository uses existing source contracts and keeps active delivery requests across days',
    () async {
      final gets = <String>[];
      final posts = <(String, dynamic)>[];
      final repo = PartnerOrdersRepository(
        get: (url, {queryParameters}) async {
          gets.add('$url|$queryParameters');
          return ApiResponse(
            state: ResponseState.complete,
            data: {
              'data': {
                'data': [],
                'meta': {'last_page': 1},
              },
            },
          );
        },
        post: (url, {body}) async {
          posts.add((url, body));
          return ApiResponse(
            state: ResponseState.complete,
            data: {'data': 'success'},
          );
        },
      );
      await repo.delivery('current');
      expect(gets.single, contains('status: current'));
      expect(gets.single, isNot(contains('home')));
      await repo.update(deliveryOrder(7, 'pending'), PartnerOrderAction.accept);
      expect(posts.last.$1, '${Urls.delegateAcceptDecline}7');
      expect((posts.last.$2 as FormData).fields.single.value, 'accept');
      await repo.update(serviceOrder(7, 'pending'), PartnerOrderAction.accept);
      expect(posts.last.$1, Urls.updateDelegateServiceRequest(7));
      expect(posts.last.$2, {'status': 'accepted'});
      await repo.update(
        deliveryOrder(7, 'accepted'),
        PartnerOrderAction.pickup,
      );
      expect((posts.last.$2 as FormData).fields.single.value, 'shipped');
      await repo.update(
        deliveryOrder(7, 'shipped'),
        PartnerOrderAction.complete,
      );
      expect(posts.last.$1, '${Urls.compleatOrderDelegate}7/completed');
    },
  );
}
