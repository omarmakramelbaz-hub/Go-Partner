import 'package:flutter/material.dart';

const storeOrderStates = {
  'awaiting_payment': ['بانتظار الدفع', 'Awaiting payment'], 'pending': ['بانتظار قبول المتجر', 'Waiting for store'],
  'preparing': ['قيد التجهيز', 'Preparing'], 'ready': ['جاهز للاستلام', 'Ready'],
  'out_for_delivery': ['في الطريق إليك', 'Out for delivery'], 'completed': ['تم التسليم', 'Delivered'],
  'cancelled': ['تم الإلغاء', 'Cancelled'], 'rejected': ['رفض المتجر الطلب', 'Declined by store'],
};
const storePaymentLabels = {'cash': ['كاش', 'Cash'], 'wallet': ['رصيد محفظة التطبيق', 'App wallet'],
  'mobile_wallet': ['محفظة إلكترونية', 'Mobile wallet'], 'card': ['بطاقة بنكية', 'Bank card']};
String storeState(Object? key, bool ar) => storeOrderStates['$key']?[ar ? 0 : 1] ?? '$key';
String storePayment(Object? key, bool ar) => storePaymentLabels['$key']?[ar ? 0 : 1] ?? '$key';

class StorePhoto extends StatelessWidget {
  const StorePhoto({super.key, this.url, this.size = 72});
  final String? url;
  final double size;
  @override
  Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(14), child: SizedBox(width: size, height: size,
    child: url == null || url!.isEmpty ? const ColoredBox(color: Color(0xFFFFF0E4), child: Icon(Icons.shopping_bag_outlined))
      : Image.network(url!, fit: BoxFit.cover, webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined))));
}

class StoreTotalRow extends StatelessWidget {
  const StoreTotalRow(this.label, this.amount, {super.key, required this.ar, this.strong = false});
  final String label;
  final Object? amount;
  final bool ar, strong;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [
    Expanded(child: Text(label, style: TextStyle(fontWeight: strong ? FontWeight.bold : null))), const SizedBox(width: 12),
    Text('$amount ${ar ? 'ج.م' : 'EGP'}', style: TextStyle(fontSize: strong ? 20 : 15, fontWeight: strong ? FontWeight.bold : null)),
  ]));
}

class StoreOrderBody extends StatelessWidget {
  const StoreOrderBody({super.key, required this.order, required this.ar, this.partner = false});
  final Map<String, dynamic> order;
  final bool ar, partner;
  @override
  Widget build(BuildContext context) {
    final address = order['address'] is Map ? order['address'] as Map : null;
    final paymentStatus = '${order['payment_status']}';
    final paymentText = {
      'cash_due': ['المبلغ يُحصّل كاش عند التسليم', 'Cash is due on delivery'], 'cash_collected': ['تم تحصيل الكاش', 'Cash collected'],
      'held': ['تم حجز قيمة الطلب من محفظة العميل', 'Order amount reserved from customer wallet'], 'paid': ['تم تأكيد الدفع', 'Payment confirmed'],
      'ready': ['الطلب ينتظر إتمام الدفع', 'Complete payment to send the order'], 'creating': ['جارٍ التحقق من تجهيز الدفع؛ لا تدفع مرة ثانية', 'Payment is being verified; do not pay again'],
      'pending': ['بانتظار تأكيد Paymob', 'Waiting for Paymob confirmation'], 'refund_pending': ['استرداد المبلغ قيد المتابعة مع الدعم', 'Refund pending with support'],
      'refunded': ['تم رد المبلغ', 'Amount refunded'], 'review': ['الدفع تحت المراجعة؛ تواصل مع الدعم', 'Payment under review; contact support'],
      'cancelled': ['تم إغلاق الدفع', 'Payment closed'],
    }[paymentStatus]?[ar ? 0 : 1];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFFFF0E4), borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${order['number']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)), const SizedBox(height: 8),
          Text(storeState(order['status'], ar), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8), Text('${order['store_name']}'),
        ])),
      const SizedBox(height: 18),
      if (partner) ...[Text('${order['customer_name']}', style: const TextStyle(fontWeight: FontWeight.bold)), SelectableText('${order['customer_mobile']}'), const SizedBox(height: 12)],
      Text(order['fulfillment'] == 'delivery' ? (ar ? 'توصيل إلى العنوان' : 'Delivery address') : (ar ? 'الاستلام من المتجر' : 'Store pickup'), style: const TextStyle(fontWeight: FontWeight.bold)),
      Text(address == null ? '${order['store_address'] ?? ''}' : [address['address'], address['street_name'],
        if ('${address['floor_no'] ?? ''}'.isNotEmpty) '${ar ? 'الدور' : 'Floor'} ${address['floor_no']}',
        if ('${address['apartment_no'] ?? ''}'.isNotEmpty) '${ar ? 'الشقة' : 'Apt'} ${address['apartment_no']}',
      ].where((e) => e != null && '$e'.isNotEmpty).join(' · ')),
      if ('${order['notes'] ?? ''}'.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text('${ar ? 'ملاحظات' : 'Notes'}: ${order['notes']}')),
      const SizedBox(height: 16), const Divider(),
      for (final item in order['items'] as List? ?? []) Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [
        StorePhoto(url: item['image_url']?.toString(), size: 60), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${item['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text('${item['option_label'] ?? item['unit'] ?? ''} × ${item['quantity']}'), Text('${item['line_total']} ${ar ? 'ج.م' : 'EGP'}')]))])),
      const Divider(), StoreTotalRow(ar ? 'المنتجات' : 'Products', order['subtotal'], ar: ar),
      StoreTotalRow(ar ? 'التوصيل' : 'Delivery', order['delivery'], ar: ar),
      StoreTotalRow(ar ? 'الإجمالي' : 'Total', order['total'], ar: ar, strong: true),
      if (partner) StoreTotalRow('${ar ? 'عمولة التطبيق' : 'App commission'} (${order['commission_rate']}%)', order['commission'], ar: ar),
      const SizedBox(height: 12), Text(storePayment(order['payment_method'], ar), style: const TextStyle(fontWeight: FontWeight.bold)),
      if (paymentText != null) Text(paymentText),
      if ('${order['reason'] ?? ''}'.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 14), child: Text('${ar ? 'السبب' : 'Reason'}: ${order['reason']}')),
    ]);
  }
}
