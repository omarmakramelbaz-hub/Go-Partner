import 'package:flutter/material.dart';

/// The route can keep its TextField mounted during the reverse animation after
/// Navigator.pop completes. The dialog, not the caller awaiting showDialog,
/// must therefore own and dispose the controller.
class PartnerPriceOfferDialog extends StatefulWidget {
  const PartnerPriceOfferDialog({
    super.key,
    required this.initialPrice,
    required this.ar,
    this.revision = false,
  });

  final String initialPrice;
  final bool ar;
  final bool revision;

  @override
  State<PartnerPriceOfferDialog> createState() => _PartnerPriceOfferDialogState();
}

class _PartnerPriceOfferDialogState extends State<PartnerPriceOfferDialog> {
  late final TextEditingController _price;
  bool _invalid = false;
  bool _closing = false;

  String _t(String ar, String en) => widget.ar ? ar : en;

  @override
  void initState() {
    super.initState();
    _price = TextEditingController(text: widget.initialPrice);
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  void _submit() {
    if (_closing) return;
    var text = _price.text.trim().replaceAll('٫', '.');
    for (var digit = 0; digit < 10; digit++) {
      text = text.replaceAll('٠١٢٣٤٥٦٧٨٩'[digit], '$digit')
          .replaceAll('۰۱۲۳۴۵۶۷۸۹'[digit], '$digit');
    }
    final amount = num.tryParse(text);
    if (amount == null || !amount.isFinite || amount <= 0) {
      setState(() => _invalid = true);
      return;
    }
    _closing = true;
    Navigator.of(context).pop<num>(amount);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.revision
        ? _t('عرض سعر جديد', 'New price offer')
        : _t('إرسال عرض سعر', 'Send price offer')),
    content: TextField(
      key: const ValueKey('partner-offer-price'),
      controller: _price,
      autofocus: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _submit(),
      onChanged: (_) {
        if (_invalid) setState(() => _invalid = false);
      },
      decoration: InputDecoration(
        labelText: widget.revision
            ? _t('السعر الجديد', 'New price')
            : _t('سعر التوصيل', 'Delivery price'),
        suffixText: _t('جنيه', 'EGP'),
        errorText: _invalid
            ? _t('أدخل سعرًا صحيحًا أكبر من صفر', 'Enter a valid price above zero')
            : null,
      ),
    ),
    actions: [
      TextButton(
        key: const ValueKey('partner-offer-cancel'),
        onPressed: () {
          if (_closing) return;
          _closing = true;
          Navigator.of(context).pop();
        },
        child: Text(_t('إلغاء', 'Cancel')),
      ),
      FilledButton(
        key: const ValueKey('partner-offer-submit'),
        onPressed: _submit,
        child: Text(widget.revision
            ? _t('إرسال', 'Send')
            : _t('إرسال العرض', 'Send offer')),
      ),
    ],
  );
}
