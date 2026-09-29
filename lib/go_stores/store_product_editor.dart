import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../go_services/service_api.dart';
import 'store_api.dart';
import 'store_catalog.dart' show storeOrange;

class StoreProductEditor extends StatefulWidget {
  const StoreProductEditor({
    super.key,
    required this.api,
    this.product,
    this.pickImage,
  });
  final StoreApi api;
  final Map<String, dynamic>? product;
  final Future<XFile?> Function()? pickImage;
  @override
  State<StoreProductEditor> createState() => _StoreProductEditorState();
}

class _Option {
  _Option({this.id, String label = '', String price = ''})
    : label = TextEditingController(text: label),
      price = TextEditingController(text: price);
  final String? id;
  final TextEditingController label;
  final TextEditingController price;
  void dispose() {
    label.dispose();
    price.dispose();
  }
}

class _StoreProductEditorState extends State<StoreProductEditor> {
  final _form = GlobalKey<FormState>();
  final _key = const Uuid().v4();
  late final _name = TextEditingController(
    text: widget.product?['name']?.toString(),
  );
  late final _description = TextEditingController(
    text: widget.product?['description']?.toString(),
  );
  late final _unit = TextEditingController(
    text: widget.product?['unit']?.toString() ?? '',
  );
  late final _price = TextEditingController(
    text: widget.product?['price']?.toString(),
  );
  late final _options = serviceMaps(widget.product?['options'])
      .map(
        (o) => _Option(
          id: o['id']?.toString(),
          label: '${o['label']}',
          price: '${o['price']}',
        ),
      )
      .toList();
  late bool _available = widget.product?['available'] != false;
  XFile? _image;
  Uint8List? _preview;
  bool _busy = false;
  bool _picking = false;
  bool _conflict = false;
  String? _error;
  bool get _ar => context.locale.languageCode == 'ar';
  String _t(String ar, String en) => _ar ? ar : en;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _unit.dispose();
    _price.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final image =
          await (widget.pickImage?.call() ??
              ImagePicker().pickImage(
                source: ImageSource.gallery,
                maxWidth: 2000,
                maxHeight: 2000,
                imageQuality: 85,
              ));
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024)
        throw ServiceFailure(
          _t('اختر صورة أقل من 5 ميجا.', 'Choose an image smaller than 5 MB.'),
        );
      if (mounted)
        setState(() {
          _image = image;
          _preview = bytes;
        });
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (widget.product == null && _image == null) {
      setState(() => _error = _t('أضف صورة للمنتج.', 'Add a product photo.'));
      return;
    }
    final labels = _options
        .map((o) => o.label.text.trim().toLowerCase())
        .toList();
    if (labels.toSet().length != labels.length) {
      setState(
        () => _error = _t(
          'اكتب اسمًا مختلفًا لكل اختيار.',
          'Use a different name for each option.',
        ),
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.saveProduct(
        {
          'request_key': _key,
          'revision': widget.product?['revision'],
          'name': _name.text.trim(),
          'description': _description.text.trim(),
          'unit': _unit.text.trim(),
          'price': storePrice(_price.text),
          'available': _available,
          'options': _options
              .map(
                (o) => {
                  if (o.id != null) 'id': o.id,
                  'label': o.label.text.trim(),
                  'price': storePrice(o.price.text),
                },
              )
              .toList(),
        },
        id: widget.product == null ? null : serviceId(widget.product!['id']),
        image: _image,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted)
        setState(() {
          _error = '$error';
          _conflict = error is ServiceFailure && error.status == 409;
        });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _validatePrice(String? value) => storePrice(value ?? '') == null
      ? _t(
          'اكتب سعرًا من 0.01 إلى 1000000 جنيه.',
          'Enter a price from EGP 0.01 to 1,000,000.',
        )
      : null;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null
              ? _t('إضافة منتج', 'Add product')
              : _t('تعديل المنتج', 'Edit product'),
        ),
      ),
      body: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _busy || _picking ? null : _pick,
                child: Container(
                  height: 190,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xffF6F7F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xffE0E3E8)),
                  ),
                  child: _preview != null
                      ? Image.memory(_preview!, fit: BoxFit.contain)
                      : widget.product != null
                      ? Image.network(
                          '${widget.product!['image_url']}',
                          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.image_outlined, size: 60),
                        )
                      : const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 60,
                          color: storeOrange,
                        ),
                ),
              ),
              TextButton.icon(
                onPressed: _busy || _picking ? null : _pick,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(_t('اختيار صورة المنتج', 'Choose product photo')),
              ),
              Text(
                _t(
                  'JPG / PNG / WEBP — بحد أقصى 5 ميجا',
                  'JPG / PNG / WEBP — up to 5 MB',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _name,
                enabled: !_busy,
                maxLength: 150,
                decoration: InputDecoration(
                  labelText: _t('اسم المنتج', 'Product name'),
                ),
                validator: (v) => (v?.trim().length ?? 0) < 2
                    ? _t('اكتب اسم المنتج', 'Enter a product name')
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                enabled: !_busy,
                maxLength: 2000,
                minLines: 2,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: _t('الوصف (اختياري)', 'Description (optional)'),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unit,
                enabled: !_busy,
                maxLength: 40,
                decoration: InputDecoration(
                  labelText: _t('الوحدة الأساسية', 'Base unit'),
                  hintText: _t('كيلو، عبوة، قطعة…', 'Kilo, pack, piece…'),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? _t('حدد وحدة البيع', 'Enter a unit')
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _price,
                enabled: !_busy,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: _t('سعر الوحدة بالجنيه', 'Unit price in EGP'),
                ),
                validator: _validatePrice,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_t('المنتج متوفر', 'Product available')),
                subtitle: Text(
                  _t(
                    'أوقفه مؤقتًا عند نفاد المنتج.',
                    'Turn off temporarily when out of stock.',
                  ),
                ),
                value: _available,
                onChanged: _busy ? null : (v) => setState(() => _available = v),
              ),
              const Divider(height: 32),
              Text(
                _t('خيارات المنتج', 'Product options'),
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _t(
                  'أضف اختيارًا وسعره الكامل، مثل نصف كيلو أو ربع كيلو. السعر مستقل عن سعر الوحدة الأساسية.',
                  'Add an option with its full price, such as half a kilo or a quarter kilo. Each price is independent of the base unit.',
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  for (final label in [
                    _t('نصف كيلو', 'Half kilo'),
                    _t('ربع كيلو', 'Quarter kilo'),
                  ])
                    ActionChip(
                      label: Text('+ $label'),
                      onPressed:
                          _busy ||
                              _options.length >= 20 ||
                              _options.any((o) => o.label.text == label)
                          ? null
                          : () => setState(
                              () => _options.add(_Option(label: label)),
                            ),
                    ),
                ],
              ),
              for (final option in _options)
                Padding(
                  key: ObjectKey(option),
                  padding: const EdgeInsets.only(top: 16),
                  child: Card(
                    elevation: 0,
                    color: const Color(0xffF6F7F9),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _t('اختيار المنتج', 'Product option'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: _t('حذف الاختيار', 'Remove option'),
                                onPressed: _busy
                                    ? null
                                    : () {
                                        setState(() => _options.remove(option));
                                        WidgetsBinding.instance
                                            .addPostFrameCallback(
                                              (_) => option.dispose(),
                                            );
                                      },
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          TextFormField(
                            controller: option.label,
                            enabled: !_busy,
                            maxLength: 60,
                            decoration: InputDecoration(
                              labelText: _t('اسم الاختيار', 'Option name'),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? _t(
                                    'اكتب اسم الاختيار',
                                    'Enter an option name',
                                  )
                                : null,
                          ),
                          TextFormField(
                            controller: option.price,
                            enabled: !_busy,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: _t(
                                'سعر الاختيار بالجنيه',
                                'Option price in EGP',
                              ),
                            ),
                            validator: _validatePrice,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _busy || _options.length >= 20
                    ? null
                    : () => setState(() => _options.add(_Option())),
                icon: const Icon(Icons.add),
                label: Text(_t('إضافة اختيار', 'Add option')),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (_conflict)
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    _t('العودة وتحديث المنتجات', 'Return and refresh products'),
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy || _picking || _conflict ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: storeOrange,
                  padding: const EdgeInsets.all(16),
                ),
                child: Text(
                  _busy
                      ? _t('جارٍ الحفظ…', 'Saving…')
                      : _t('حفظ المنتج', 'Save product'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
