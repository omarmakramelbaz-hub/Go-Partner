import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../go_services/service_api.dart';
import 'store_api.dart';
import 'store_product_editor.dart';

const storeOrange = Color(0xffFD7201);
const storeInk = Color(0xff171A1F);

class StoreCatalog extends StatefulWidget {
  const StoreCatalog({super.key, this.api});
  final StoreApi? api;
  @override
  State<StoreCatalog> createState() => _StoreCatalogState();
}

class _StoreCatalogState extends State<StoreCatalog> {
  late final StoreApi _api = widget.api ?? StoreApi();
  final _search = TextEditingController();
  Map<String, dynamic>? _data;
  String? _error;
  bool _busy = true;
  int _page = 1;
  bool get _ar => context.locale.languageCode == 'ar';
  String _t(String ar, String en) => _ar ? ar : en;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    if (widget.api == null) _api.close();
    super.dispose();
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = await _api.catalog(page: page, search: _search.text.trim());
      if (mounted)
        setState(() {
          _data = data;
          _page = page;
        });
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editStore() async {
    final data = _data?['store'];
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => StoreProfileEditor(
          api: _api,
          store: data is Map ? Map<String, dynamic>.from(data) : null,
        ),
      ),
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _editProduct([Map<String, dynamic>? product]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => StoreProductEditor(api: _api, product: product),
      ),
    );
    if (saved == true && mounted)
      await _load(page: product == null ? 1 : _page);
  }

  @override
  Widget build(BuildContext context) {
    final store = _data?['store'];
    final products = serviceMaps(_data?['products']);
    return Scaffold(
      backgroundColor: const Color(0xffF6F7F9),
      appBar: AppBar(
        backgroundColor: storeInk,
        foregroundColor: Colors.white,
        title: Text(_t('متجري', 'My store')),
        actions: [
          IconButton(
            tooltip: _t('تحديث', 'Refresh'),
            onPressed: _busy ? null : () => _load(page: _page),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: store == null || _busy || _error != null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: storeOrange,
              foregroundColor: Colors.white,
              onPressed: _editProduct,
              icon: const Icon(Icons.add),
              label: Text(_t('إضافة منتج', 'Add product')),
            ),
      body: _busy && _data == null
          ? const Center(child: CircularProgressIndicator(color: storeOrange))
          : RefreshIndicator(
              onRefresh: () => _load(page: _page),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                children: [
                  if (_busy) const LinearProgressIndicator(color: storeOrange),
                  if (_error != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _load(page: _page),
                              child: Text(_t('إعادة المحاولة', 'Retry')),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_data != null) ...[
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: storeInk,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.storefront_outlined,
                            color: storeOrange,
                            size: 40,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            store is Map
                                ? '${store['name']}'
                                : _t('جهّز متجرك', 'Set up your store'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            store is Map
                                ? '${storeKind(store['kind']?.toString(), _ar)} · ${store['address']}'
                                : _t(
                                    'أضف اسم متجرك ونشاطه وعنوانه، ثم ابدأ إضافة منتجاتك.',
                                    'Add your store name, category and address, then create your products.',
                                  ),
                            style: const TextStyle(
                              color: Colors.white70,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white38),
                            ),
                            onPressed: _busy ? null : _editStore,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: Text(_t('بيانات المتجر', 'Store details')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _t('منتجاتك', 'Your products'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: storeInk,
                      ),
                    ),
                    Text(
                      _t(
                        'صورة واضحة، سعر محدد، واختيارات تناسب عملاءك.',
                        'Clear photos, precise prices and options for your customers.',
                      ),
                      style: const TextStyle(color: Color(0xff777F8C)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _search,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) {
                        if (!_busy) _load();
                      },
                      decoration: InputDecoration(
                        labelText: _t('ابحث عن منتج', 'Search products'),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          onPressed: _busy ? null : () => _load(),
                          icon: const Icon(Icons.arrow_forward),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (products.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 54,
                              color: Color(0xffABB1B9),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _search.text.trim().isNotEmpty
                                  ? _t(
                                      'لا توجد منتجات مطابقة.',
                                      'No matching products.',
                                    )
                                  : _t(
                                      'منتجاتك هتظهر هنا',
                                      'Your products will appear here',
                                    ),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _t(
                                'يمكنك إضافة كيلو ونصف كيلو وربع كيلو بأسعار مختلفة.',
                                'Add kilo, half-kilo and quarter-kilo options with individual prices.',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 900
                            ? 3
                            : constraints.maxWidth >= 600
                            ? 2
                            : 1;
                        final width =
                            (constraints.maxWidth - (columns - 1) * 12) /
                            columns;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: products
                              .map(
                                (product) => SizedBox(
                                  width: width,
                                  child: _card(product),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                    if (serviceId(_data?['last_page']) > 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            tooltip: _t('السابق', 'Previous'),
                            onPressed: _page > 1 && !_busy
                                ? () => _load(page: _page - 1)
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text('$_page / ${_data!['last_page']}'),
                          IconButton(
                            tooltip: _t('التالي', 'Next'),
                            onPressed:
                                _page < serviceId(_data?['last_page']) && !_busy
                                ? () => _load(page: _page + 1)
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _card(Map<String, dynamic> product) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xffE7E9ED)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 180,
          width: double.infinity,
          child: ColoredBox(
            color: Colors.white,
            child: Image.network(
              '${product['image_url']}',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.image_outlined,
                size: 48,
                color: Colors.grey,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${product['name']}',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${product['price']} ${_t('ج', 'EGP')} / ${product['unit']}',
                style: const TextStyle(
                  color: storeOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product['available'] == true
                    ? _t('متوفر', 'Available')
                    : _t('غير متوفر حاليًا', 'Currently unavailable'),
                style: TextStyle(
                  color: product['available'] == true
                      ? Colors.green.shade700
                      : Colors.grey.shade700,
                ),
              ),
              if (serviceMaps(product['options']).isNotEmpty) ...[
                const Divider(height: 24),
                for (final option in serviceMaps(product['options']))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text('${option['label']}')),
                        Text('${option['price']} ${_t('ج', 'EGP')}'),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _busy || _error != null
                      ? null
                      : () => _editProduct(product),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(_t('تعديل المنتج', 'Edit product')),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class StoreProfileEditor extends StatefulWidget {
  const StoreProfileEditor({super.key, required this.api, this.store});
  final StoreApi api;
  final Map<String, dynamic>? store;
  @override
  State<StoreProfileEditor> createState() => _StoreProfileEditorState();
}

class _StoreProfileEditorState extends State<StoreProfileEditor> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.store?['name']?.toString(),
  );
  late final _address = TextEditingController(
    text: widget.store?['address']?.toString(),
  );
  late String? _kind = widget.store?['kind']?.toString();
  bool _busy = false;
  String? _error;
  bool get _ar => context.locale.languageCode == 'ar';
  String _t(String ar, String en) => _ar ? ar : en;
  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.saveStore({
        'name': _name.text.trim(),
        'kind': _kind,
        'address': _address.text.trim(),
        'revision': widget.store?['revision'] ?? 0,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: Text(_t('بيانات المتجر', 'Store details'))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              _t(
                'سوبر ماركت، مطعم أو صيدلية',
                'Supermarket, restaurant or pharmacy',
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              enabled: !_busy,
              maxLength: 150,
              decoration: InputDecoration(
                labelText: _t('اسم المتجر', 'Store name'),
              ),
              validator: (v) => (v?.trim().length ?? 0) < 2
                  ? _t('اكتب اسم المتجر', 'Enter a store name')
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _kind,
              decoration: InputDecoration(
                labelText: _t('نوع النشاط', 'Store category'),
              ),
              items: ['supermarket', 'restaurant', 'pharmacy']
                  .map(
                    (key) => DropdownMenuItem(
                      value: key,
                      child: Text(storeKind(key, _ar)),
                    ),
                  )
                  .toList(),
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _kind = value),
              validator: (v) =>
                  v == null ? _t('اختر النشاط', 'Select a category') : null,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _address,
              enabled: !_busy,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: _t('العنوان بالتفصيل', 'Detailed address'),
              ),
              validator: (v) => (v?.trim().length ?? 0) < 5
                  ? _t('اكتب العنوان بالتفصيل', 'Enter a detailed address')
                  : null,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: storeOrange),
              child: Text(
                _busy
                    ? _t('جارٍ الحفظ…', 'Saving…')
                    : _t('حفظ بيانات المتجر', 'Save store details'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
