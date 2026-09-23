import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/partner_order.dart';
import '../service/partner_orders_repository.dart';

enum PartnerOrderFeed {
  deliveryActive,
  deliveryNew,
  services,
  deliveryHistory,
  serviceHistory,
}

class PartnerOrdersController extends ChangeNotifier {
  PartnerOrdersController({
    required this.isProfessional,
    PartnerOrdersRepository? repository,
  }) : _repository = repository ?? PartnerOrdersRepository();

  final bool isProfessional;
  final PartnerOrdersRepository _repository;
  final Map<PartnerOrderFeed, PartnerOrderPage> _pages = {};
  final Map<PartnerOrderFeed, int> _loadedPages = {};
  final Map<PartnerOrderFeed, String?> errors = {};
  final Set<PartnerOrderFeed> loadingFeeds = {};
  final Set<String> _busy = {};
  static const liveRefreshInterval = Duration(seconds: 10);
  Timer? _liveTimer;
  bool _liveUpdatesEnabled = false;
  bool _refreshing = false;
  bool _refreshQueued = false;
  bool _disposed = false;
  bool _historyRequested = false;
  bool get loading => loadingFeeds.isNotEmpty;
  bool get initialized => _pages.isNotEmpty || errors.isNotEmpty;
  bool busy(PartnerOrder order) => _busy.contains(order.key);
  bool stale(PartnerOrder order) => errors.containsKey(
    order.source == PartnerOrderSource.service
        ? PartnerOrderFeed.services
        : order.isActive && !order.awaitingConfirmation
        ? PartnerOrderFeed.deliveryActive
        : PartnerOrderFeed.deliveryNew,
  );
  bool hasMore(PartnerOrderFeed feed) => _pages[feed]?.nextPage != null;
  bool get hasMoreActive => hasMore(PartnerOrderFeed.deliveryActive);
  bool get hasMoreNew => hasMore(PartnerOrderFeed.deliveryNew);
  bool get hasMoreHistory => hasMore(PartnerOrderFeed.deliveryHistory);

  List<PartnerOrder> _items(Iterable<PartnerOrderFeed> feeds) {
    final unique = <String, PartnerOrder>{};
    for (final feed in feeds) {
      for (final item in _pages[feed]?.items ?? <PartnerOrder>[]) {
        unique[item.key] = item;
      }
    }
    return unique.values.toList();
  }

  List<PartnerOrder> get active => _items([
    PartnerOrderFeed.deliveryActive,
    PartnerOrderFeed.deliveryNew,
    PartnerOrderFeed.services,
  ]).where((order) => order.isActive).toList();
  List<PartnerOrder> get incoming => _items([
    PartnerOrderFeed.deliveryNew,
    PartnerOrderFeed.services,
  ]).where((order) => order.isNew).toList();
  List<PartnerOrder> get history => _items([
    PartnerOrderFeed.deliveryHistory,
    PartnerOrderFeed.serviceHistory,
  ]).where((order) => order.isClosed).toList();

  Future<PartnerOrderPage> _fetch(PartnerOrderFeed feed, int page) =>
      switch (feed) {
        PartnerOrderFeed.deliveryActive => _repository.delivery(
          'current',
          page: page,
        ),
        PartnerOrderFeed.deliveryNew => _repository.delivery(
          'pending',
          page: page,
        ),
        PartnerOrderFeed.services => _repository.services(),
        PartnerOrderFeed.deliveryHistory => _repository.delivery(
          'completed',
          page: page,
        ),
        PartnerOrderFeed.serviceHistory => _repository.services(history: true),
      };

  Future<void> _load(PartnerOrderFeed feed, {bool more = false}) async {
    if (_disposed || loadingFeeds.contains(feed)) return;
    final page = more ? _pages[feed]?.nextPage : 1;
    if (page == null) return;
    loadingFeeds.add(feed);
    _notify();
    try {
      var result = await _fetch(feed, page);
      var lastLoaded = page;
      if (!more) {
        // Background refresh must keep pages the partner has already opened.
        while (result.nextPage != null &&
            lastLoaded < (_loadedPages[feed] ?? 1)) {
          final next = await _fetch(feed, result.nextPage!);
          result = PartnerOrderPage([
            ...result.items,
            ...next.items,
          ], nextPage: next.nextPage);
          lastLoaded++;
        }
      }
      if (_disposed) return;
      _loadedPages[feed] = lastLoaded;
      _pages[feed] = more
          ? PartnerOrderPage([
              ...?_pages[feed]?.items,
              ...result.items,
            ], nextPage: result.nextPage)
          : result;
      errors.remove(feed);
    } catch (e) {
      if (_disposed) return;
      errors[feed] = e is PartnerOrdersException ? e.message : null;
    } finally {
      loadingFeeds.remove(feed);
      _notify();
    }
  }

  Future<void> refresh() async {
    if (_disposed) return;
    if (_busy.isNotEmpty || loading || _refreshing) {
      // An event may arrive after an in-flight read took its snapshot. Fetch
      // again when that read/write finishes instead of dropping the event.
      _refreshQueued = true;
      return;
    }
    _refreshing = true;
    try {
      do {
        _refreshQueued = false;
        await _refreshFeeds();
      } while (!_disposed && _refreshQueued);
    } finally {
      _refreshing = false;
    }
  }

  void startLiveUpdates() {
    if (_disposed || _liveUpdatesEnabled) return;
    _liveUpdatesEnabled = true;
    unawaited(refresh());
    // Notifications trigger immediate reads. This also covers missed messages
    // and web sessions where push notifications are unavailable.
    _liveTimer = Timer.periodic(liveRefreshInterval, (_) {
      // Slow requests must not accumulate a queue of polling requests.
      if (!_refreshing && !loading && _busy.isEmpty) {
        unawaited(refresh());
      }
    });
  }

  void pauseLiveUpdates() {
    _liveUpdatesEnabled = false;
    _liveTimer?.cancel();
    _liveTimer = null;
  }

  void requestLiveRefresh() {
    if (_liveUpdatesEnabled && !_disposed) unawaited(refresh());
  }

  Future<void> _drainQueuedRefresh() async {
    if (_refreshQueued && !_refreshing && !loading && _busy.isEmpty) {
      await refresh();
    }
  }

  Future<void> _refreshFeeds() => Future.wait([
    if (!isProfessional) _load(PartnerOrderFeed.deliveryActive),
    if (!isProfessional) _load(PartnerOrderFeed.deliveryNew),
    _load(PartnerOrderFeed.services),
    if (_historyRequested) _loadHistoryFeeds(),
  ]);

  Future<void> loadHistory() async {
    if (_disposed || _busy.isNotEmpty) return;
    _historyRequested = true;
    await _loadHistoryFeeds();
    await _drainQueuedRefresh();
  }

  Future<void> _loadHistoryFeeds() => Future.wait([
    if (!isProfessional) _load(PartnerOrderFeed.deliveryHistory),
    _load(PartnerOrderFeed.serviceHistory),
  ]);

  Future<void> loadMore(PartnerOrderFeed feed) async {
    if (_disposed || _busy.isNotEmpty) return;
    await _load(feed, more: true);
    await _drainQueuedRefresh();
  }

  /// Keep a successful write separate from a failed subsequent refresh.
  /// A delivery acceptance may still await customer confirmation, so never
  /// invent its assigned status locally.
  Future<bool> act(PartnerOrder order, PartnerOrderAction action) async {
    if (_disposed ||
        _busy.isNotEmpty ||
        _refreshing ||
        loading ||
        stale(order) ||
        !order.allows(action)) {
      return false;
    }
    _busy.add(order.key);
    _notify();
    try {
      await _repository.update(order, action);
      if (_disposed) return true;
      for (final entry in _pages.entries) {
        _pages[entry.key] = PartnerOrderPage(
          entry.value.items.where((item) => item.key != order.key).toList(),
          nextPage: entry.value.nextPage,
        );
      }
      await _refreshFeeds();
      return true;
    } finally {
      _busy.remove(order.key);
      _notify();
      await _drainQueuedRefresh();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    pauseLiveUpdates();
    super.dispose();
  }
}
