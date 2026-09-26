import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../global/partner/partner_identity.dart';
import '../controller/partner_orders_controller.dart';
import '../model/partner_order.dart';
import '../screen/order_details_delegate_screen.dart';
import '../service/partner_orders_repository.dart';

String _t(BuildContext context, String ar, String en) =>
    context.locale.languageCode == 'ar' ? ar : en;
const _orange = PartnerIdentity.orange;
const _ink = PartnerIdentity.ink;
const _muted = Color(0xff7D8490);

/// The same cards and actions serve couriers and trade professionals.
class PartnerOrdersBoard extends StatefulWidget {
  const PartnerOrdersBoard({super.key, this.onViewAll, this.section});
  final VoidCallback? onViewAll;

  /// null: home overview, 0: new requests, 1: current, 2: history.
  final int? section;
  @override
  State<PartnerOrdersBoard> createState() => _PartnerOrdersBoardState();
}

class _PartnerOrdersBoardState extends State<PartnerOrdersBoard> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<PartnerOrdersController>();
    final overview = widget.section == null;
    final active = orders.active;
    final incoming = orders.incoming;
    final selected =
        active.where((item) => item.key == _selected).firstOrNull ??
        active.firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (overview)
          Row(
            children: [
              const Icon(Icons.assignment_outlined, color: _orange, size: 23),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _t(context, 'طلبات العملاء', 'Customer requests'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
              Text(
                _t(context, 'تحديث تلقائي', 'Auto-updates'),
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
            ],
          ),
        if (orders.loading && !orders.initialized)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: LinearProgressIndicator(color: _orange, minHeight: 2),
          ),
        if (orders.errors.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xffFFF4E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t(
                    context,
                    'تعذر تحديث بعض الطلبات. سنعيد المحاولة تلقائيًا؛ البيانات الظاهرة قد تكون غير محدثة.',
                    'Some requests could not be refreshed. Retrying automatically; displayed information may be out of date.',
                  ),
                  style: const TextStyle(fontSize: 13, color: _ink),
                ),
                TextButton(
                  onPressed: orders.loading ? null : orders.refresh,
                  child: Text(_t(context, 'إعادة المحاولة', 'Retry')),
                ),
              ],
            ),
          ),
        if (!orders.initialized && orders.loading)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _t(context, 'جارٍ تحميل الطلبات…', 'Loading requests…'),
              textAlign: TextAlign.center,
            ),
          )
        else ...[
          if (overview || widget.section == 1) ...[
            _heading(
              _t(context, 'الطلب الجاري', 'Current request'),
              active.length,
              more: orders.hasMoreActive,
            ),
            const SizedBox(height: 10),
            if (overview && active.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DropdownButtonFormField<String>(
                  key: ValueKey('selected-${selected?.key}'),
                  initialValue: selected?.key,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: _t(
                      context,
                      'اختيار طلب جاري',
                      'Choose a current request',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: active
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.key,
                          child: Text(
                            '#${item.number} · ${item.title(context.locale.languageCode == 'ar')}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selected = value),
                ),
              ),
            if (active.isEmpty && orders.errors.isEmpty)
              _empty(
                _t(context, 'لا يوجد طلب جاري', 'No current request'),
                _t(
                  context,
                  'عند تأكيد قبول الطلب، تقدر تتابع مراحله هنا.',
                  'Track a request here once it is accepted.',
                ),
                dark: true,
              )
            else if (overview && selected != null)
              PartnerOrderCard(order: selected, current: true)
            else if (!overview)
              ...active.map(
                (item) => PartnerOrderCard(order: item, current: true),
              ),
            if (orders.hasMoreActive)
              _more(orders, PartnerOrderFeed.deliveryActive),
          ],
          if (overview) const SizedBox(height: 20),
          if (overview || widget.section == 0) ...[
            _heading(
              _t(context, 'طلبات جديدة', 'New requests'),
              incoming.length,
              more: orders.hasMoreNew,
            ),
            const SizedBox(height: 4),
            Text(
              _t(
                context,
                'راجع التفاصيل واقبل أو ارفض الطلب المناسب لك.',
                'Review the details, then accept or decline a request.',
              ),
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (incoming.isEmpty && orders.errors.isEmpty)
              _empty(
                _t(
                  context,
                  'لا توجد طلبات جديدة حاليًا',
                  'No new requests right now',
                ),
                _t(
                  context,
                  'طلبات العملاء المرسلة لحسابك هتظهر هنا.',
                  'Customer requests sent to your account will appear here.',
                ),
              ),
            ...(overview ? incoming.take(2) : incoming).map(
              (item) => PartnerOrderCard(order: item),
            ),
            if (overview && widget.onViewAll != null)
              TextButton.icon(
                onPressed: widget.onViewAll,
                icon: const Icon(Icons.list_alt_rounded),
                label: Text(_t(context, 'عرض كل الطلبات', 'View all requests')),
              )
            else if (orders.hasMoreNew)
              _more(orders, PartnerOrderFeed.deliveryNew),
          ],
          if (widget.section == 2) ...[
            if (orders.history.isEmpty &&
                !orders.loading &&
                orders.errors.isEmpty)
              _empty(
                _t(context, 'لا توجد طلبات سابقة', 'No previous requests'),
                _t(
                  context,
                  'الطلبات المنتهية ستظهر هنا.',
                  'Closed requests will appear here.',
                ),
              ),
            ...orders.history.map((item) => PartnerOrderCard(order: item)),
            if (orders.hasMoreHistory)
              _more(orders, PartnerOrderFeed.deliveryHistory),
          ],
        ],
      ],
    );
  }

  Widget _heading(String title, int count, {bool more = false}) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xffFFF0E5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$count${more ? '+' : ''}',
          style: const TextStyle(color: _orange, fontWeight: FontWeight.bold),
        ),
      ),
    ],
  );

  Widget _more(PartnerOrdersController orders, PartnerOrderFeed feed) =>
      TextButton(
        onPressed: orders.loading ? null : () => orders.loadMore(feed),
        child: Text(_t(context, 'تحميل طلبات أخرى', 'Load more requests')),
      );

  Widget _empty(String title, String subtitle, {bool dark = false}) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: dark ? _ink : const Color(0xffF7F8FA),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(
              dark ? Icons.route_outlined : Icons.inbox_outlined,
              color: _orange,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: dark ? Colors.white : _ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: dark ? Colors.white70 : _muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class PartnerOrderCard extends StatelessWidget {
  const PartnerOrderCard({
    super.key,
    required this.order,
    this.current = false,
  });
  final PartnerOrder order;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final ar = context.locale.languageCode == 'ar';
    final controller = context.watch<PartnerOrdersController>();
    final busy = controller.busy(order);
    final enabled = !busy && !controller.loading && !controller.stale(order);
    final color = current ? Colors.white : _ink;
    final secondary = current ? Colors.white70 : _muted;
    final next = order.allows(PartnerOrderAction.pickup)
        ? PartnerOrderAction.pickup
        : order.allows(PartnerOrderAction.complete)
        ? PartnerOrderAction.complete
        : null;
    return Container(
      key: ValueKey('order-${order.key}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: current ? _ink : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: current ? _ink : PartnerIdentity.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: current
                      ? Colors.white.withValues(alpha: .08)
                      : const Color(0xffFFF0E5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  order.isDelivery
                      ? Icons.delivery_dining_rounded
                      : Icons.handyman_outlined,
                  color: _orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.title(ar),
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '#${order.number}',
                      style: TextStyle(color: secondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _badge(
                order.isDelivery
                    ? _t(context, 'توصيل', 'Delivery')
                    : _t(context, 'خدمة', 'Service'),
                secondary,
              ),
              _badge(order.statusLabel(ar), _orange),
            ],
          ),
          if (current && !order.awaitingConfirmation) ...[
            const SizedBox(height: 18),
            _progress(ar),
          ],
          if (order.awaitingConfirmation)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _t(
                  context,
                  'تم إرسال قبولك. تبدأ مراحل التنفيذ بعد تأكيد العميل.',
                  'Your acceptance was sent. Work begins after the customer confirms.',
                ),
                style: TextStyle(color: secondary, fontSize: 12, height: 1.5),
              ),
            ),
          if (order.customer.isNotEmpty)
            _info(Icons.person_outline_rounded, order.customer, secondary),
          if (order.pickupAddress.isNotEmpty)
            _info(
              Icons.storefront_outlined,
              '${_t(context, 'الاستلام', 'Pickup')}: ${order.pickupAddress}',
              secondary,
            ),
          if (order.address.isNotEmpty)
            _info(Icons.location_on_outlined, order.address, secondary),
          if (order.description.isNotEmpty)
            _info(Icons.notes_rounded, order.description, secondary),
          if (order.scheduledAt?.isNotEmpty == true)
            _info(Icons.schedule_rounded, _schedule(context), secondary),
          if (order.delivery?.deliveryPrice != null)
            _info(
              Icons.payments_outlined,
              '${_t(context, 'رسوم التوصيل', 'Delivery fee')}: ${order.delivery!.deliveryPrice} ${_t(context, 'جنيه', 'EGP')}',
              secondary,
            ),
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: busy ? null : () => _details(context, controller),
              style: TextButton.styleFrom(
                foregroundColor: current ? Colors.white : _ink,
              ),
              icon: const Icon(Icons.open_in_new_rounded, size: 17),
              label: Text(_t(context, 'تفاصيل الطلب', 'Request details')),
            ),
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: LinearProgressIndicator(color: _orange),
            ),
          if (order.isNew)
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    key: ValueKey('accept-${order.key}'),
                    onPressed: enabled
                        ? () => order.isDelivery
                            ? _offer(context, controller)
                            : _act(context, controller, PartnerOrderAction.accept)
                        : null,
                    style: _buttonStyle(),
                    icon: const Icon(Icons.check_rounded, size: 19),
                    label: Text(order.isDelivery
                        ? _t(context, 'إرسال عرض سعر', 'Send price offer')
                        : _t(context, 'قبول الطلب', 'Accept')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    key: ValueKey('decline-${order.key}'),
                    onPressed: enabled
                        ? () => _act(
                            context,
                            controller,
                            PartnerOrderAction.decline,
                          )
                        : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xffB84436),
                      minimumSize: const Size(0, 46),
                      side: const BorderSide(color: Color(0xffECD6D2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_t(context, 'رفض', 'Decline')),
                  ),
                ),
              ],
            ),
          if (current && order.isDelivery && !order.awaitingConfirmation) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: enabled ? () => _reviseOffer(context, controller) : null,
              icon: const Icon(Icons.price_change_outlined),
              label: Text(_t(context, 'إرسال عرض سعر جديد', 'Send a new price offer')),
            ),
          ],
          if (next != null)
            FilledButton.icon(
              key: ValueKey('advance-${order.key}'),
              onPressed: enabled ? () => _act(context, controller, next) : null,
              style: _buttonStyle(),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
              label: Text(
                next == PartnerOrderAction.pickup
                    ? _t(context, 'تم استلام الطلب', 'Confirm pickup')
                    : order.isDelivery
                    ? _t(context, 'تم توصيل الطلب', 'Confirm delivery')
                    : _t(context, 'تم تنفيذ الخدمة', 'Complete service'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _reviseOffer(
    BuildContext context,
    PartnerOrdersController controller,
  ) async {
    final price = TextEditingController(
      text: order.delivery?.deliveryPrice?.toString() ?? '',
    );
    final value = await showDialog<num>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t(context, 'عرض سعر جديد', 'New price offer')),
        content: TextField(
          controller: price,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: _t(context, 'السعر الجديد', 'New price'),
            suffixText: _t(context, 'جنيه', 'EGP'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_t(context, 'إلغاء', 'Cancel')),
          ),
          FilledButton(
            onPressed: () {
              final amount = num.tryParse(price.text.trim());
              if (amount != null && amount > 0) Navigator.pop(dialogContext, amount);
            },
            child: Text(_t(context, 'إرسال', 'Send')),
          ),
        ],
      ),
    );
    price.dispose();
    if (value == null || !context.mounted) return;
    final ok = await controller.reviseOffer(order, value);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok
          ? _t(context, 'تم إرسال العرض الجديد للعميل', 'New offer sent to customer')
          : _t(context, 'تعذر إرسال العرض', 'Could not send offer'))),
    );
  }

  Future<void> _offer(
    BuildContext context,
    PartnerOrdersController controller,
  ) async {
    final price = TextEditingController(
      text: order.delivery?.deliveryPrice?.toString() ?? '',
    );
    final value = await showDialog<num>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t(context, 'إرسال عرض سعر', 'Send price offer')),
        content: TextField(
          controller: price,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: _t(context, 'سعر التوصيل', 'Delivery price'),
            suffixText: _t(context, 'جنيه', 'EGP'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_t(context, 'إلغاء', 'Cancel')),
          ),
          FilledButton(
            onPressed: () {
              final amount = num.tryParse(price.text.trim());
              if (amount != null && amount > 0) {
                Navigator.pop(dialogContext, amount);
              }
            },
            child: Text(_t(context, 'إرسال العرض', 'Send offer')),
          ),
        ],
      ),
    );
    price.dispose();
    if (value == null || !context.mounted) return;
    final ok = await controller.submitOffer(order, value);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? _t(context, 'تم إرسال عرض السعر للعميل', 'Price offer sent to customer')
              : _t(context, 'تعذر إرسال عرض السعر', 'Could not send price offer'),
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle() => FilledButton.styleFrom(
    backgroundColor: _orange,
    foregroundColor: Colors.white,
    minimumSize: const Size(0, 46),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  String _schedule(BuildContext context) {
    final date = DateTime.tryParse(order.scheduledAt ?? '');
    return date == null
        ? order.scheduledAt!
        : DateFormat.yMd(
            context.locale.languageCode,
          ).add_jm().format(date.toLocal());
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );

  Widget _info(IconData icon, String text, Color color) => Padding(
    padding: const EdgeInsets.only(top: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _orange, size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontSize: 12, height: 1.4),
          ),
        ),
      ],
    ),
  );

  Widget _progress(bool ar) {
    final labels = order.steps(ar);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < labels.length; index++)
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index == 0
                            ? Colors.transparent
                            : (index <= order.step ? _orange : Colors.white24),
                      ),
                    ),
                    Container(
                      width: 27,
                      height: 27,
                      decoration: BoxDecoration(
                        color: index <= order.step
                            ? _orange
                            : const Color(0xff373A3F),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: index < order.step
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 17,
                              )
                            : Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index == labels.length - 1
                            ? Colors.transparent
                            : (index < order.step ? _orange : Colors.white24),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: index <= order.step ? Colors.white : Colors.white54,
                    fontWeight: index == order.step
                        ? FontWeight.w800
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _act(
    BuildContext context,
    PartnerOrdersController controller,
    PartnerOrderAction action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final failure = _t(
      context,
      'تعذر تحديث الطلب. حاول مرة أخرى.',
      'Could not update the request. Try again.',
    );
    final text = switch (action) {
      PartnerOrderAction.accept => _t(
        context,
        'تم إرسال قبول الطلب',
        'Acceptance sent',
      ),
      PartnerOrderAction.decline => _t(
        context,
        'تم رفض الطلب',
        'Request declined',
      ),
      PartnerOrderAction.pickup => _t(
        context,
        'تم تأكيد الاستلام',
        'Pickup confirmed',
      ),
      PartnerOrderAction.complete => _t(
        context,
        'تم إتمام الطلب',
        'Request completed',
      ),
    };
    try {
      if (!await controller.act(order, action) || !messenger.mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));
    } catch (e) {
      if (!messenger.mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e is PartnerOrdersException && e.message?.isNotEmpty == true
                  ? e.message!
                  : failure,
            ),
          ),
        );
    }
  }

  Future<void> _details(
    BuildContext context,
    PartnerOrdersController controller,
  ) async {
    if (order.delivery != null) {
      await Navigator.of(context).pushNamed(
        OrderDetailsDelegateScreen.routeName,
        arguments: OrderDetailsDelegateScreenArgs(
          fromHome: true,
          orderId: order.id,
        ),
      );
      if (context.mounted) await controller.refresh();
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${order.title(context.locale.languageCode == 'ar')} #${order.number}',
                style: const TextStyle(
                  fontSize: 21,
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                order.statusLabel(context.locale.languageCode == 'ar'),
                style: const TextStyle(color: _orange),
              ),
              const SizedBox(height: 12),
              Text(
                order.description,
                style: const TextStyle(height: 1.6, color: _ink),
              ),
              if (order.customer.isNotEmpty)
                _info(Icons.person_outline, order.customer, _ink),
              if (order.phone.isNotEmpty)
                SelectableText(
                  order.phone,
                  style: const TextStyle(color: _ink),
                ),
              if (order.address.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(order.address),
                ),
              if (order.scheduledAt?.isNotEmpty == true)
                _info(Icons.schedule, _schedule(context), _ink),
              if (order.photos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: order.photos
                        .map(
                          (url) => ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              url,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                width: 120,
                                height: 120,
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              if (order.mapUri != null)
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      if (!await launchUrl(
                        order.mapUri!,
                        mode: LaunchMode.externalApplication,
                      )) {
                        throw StateError('map');
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _t(
                                context,
                                'تعذر فتح الخريطة',
                                'Could not open the map',
                              ),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: Text(_t(context, 'موقع العميل', 'Customer location')),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(_t(context, 'إغلاق', 'Close')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
