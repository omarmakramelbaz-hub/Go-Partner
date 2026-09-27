import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'store_signup_draft.dart';

const _orange = Color(0xFFFD7201);
const _navy = Color(0xFF171A1F);
const _background = Color(0xFFF7F8FA);
InputDecoration _field(String label) => InputDecoration(
  labelText: label,
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
);
Widget _card(Widget child) => Card(
  elevation: 0,
  color: Colors.white,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  child: Padding(padding: const EdgeInsets.all(18), child: child),
);

Future<SignupImage?> _pickImage() async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1200,
    maxHeight: 1200,
    imageQuality: 75,
  );
  return file == null ? null : SignupImage.fromFile(file);
}

class StoreSignupScreen extends StatefulWidget {
  const StoreSignupScreen({
    super.key,
    required this.draft,
    required this.onSubmit,
    this.pickImage,
  });
  final StoreSignupDraft draft;
  final Future<bool> Function() onSubmit;
  final Future<SignupImage?> Function()? pickImage;
  @override
  State<StoreSignupScreen> createState() => _StoreSignupScreenState();
}

class _StoreSignupScreenState extends State<StoreSignupScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.draft.name);
  late final _address = TextEditingController(text: widget.draft.address);
  bool _busy = false, _picking = false;
  String? _error;
  StoreSignupDraft get draft => widget.draft;
  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _logo() async {
    setState(() => _picking = true);
    try {
      final image = await (widget.pickImage ?? _pickImage)();
      if (image != null && mounted) setState(() => draft.logo = image);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _product([int? index]) async {
    final result = await Navigator.push<SignupProduct>(
      context,
      MaterialPageRoute(
        builder: (_) => SignupProductScreen(
          product: index == null ? null : draft.products[index],
          pickImage: widget.pickImage,
        ),
      ),
    );
    if (result != null && mounted)
      setState(() {
        if (index == null) {
          draft.products.add(result);
        } else {
          draft.products[index] = result;
        }
      });
  }

  Future<void> _submit() async {
    if (_busy || _picking || !_form.currentState!.validate()) return;
    final error = draft.validate();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (await widget.onSubmit() && mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          title: const Text('تجهيز متجرك'),
          backgroundColor: _background,
          surfaceTintColor: Colors.transparent,
        ),
        body: SafeArea(
          child: AbsorbPointer(
            absorbing: _busy || _picking,
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _card(
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '٢ من ٢ • المتجر والمنتجات',
                          style: TextStyle(
                            color: _orange,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'ابدأ بمتجر جاهز من أول يوم',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: _navy,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'جهّز اللوجو والمنتجات والأسعار. هيتراجعوا مع طلب انضمامك، وتقدر تديرهم بعد الموافقة وتفعيل حسابك.',
                          style: TextStyle(height: 1.6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'بيانات المتجر',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: InkWell(
                            onTap: _logo,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 112,
                              height: 112,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1E7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: _picking
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : draft.logo == null
                                  ? const Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 38,
                                      color: _orange,
                                    )
                                  : Image.memory(
                                      draft.logo!.bytes,
                                      fit: BoxFit.contain,
                                    ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _logo,
                          child: Text(
                            draft.logo == null
                                ? 'إضافة لوجو المتجر'
                                : 'تغيير اللوجو',
                          ),
                        ),
                        TextFormField(
                          controller: _name,
                          decoration: _field('اسم المتجر'),
                          maxLength: 150,
                          onChanged: (v) => draft.name = v,
                          validator: (v) => (v ?? '').trim().length < 2
                              ? 'اكتب اسم المتجر'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: draft.kind,
                          isExpanded: true,
                          decoration: _field('نوع النشاط'),
                          items: signupKinds.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => draft.kind = v),
                          validator: (v) => v == null ? 'اختر النشاط' : null,
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _address,
                          decoration: _field('العنوان بالتفصيل'),
                          maxLength: 500,
                          minLines: 2,
                          maxLines: 3,
                          onChanged: (v) => draft.address = v,
                          validator: (v) => (v ?? '').trim().length < 5
                              ? 'اكتب العنوان بالتفصيل'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'المنتجات (${draft.products.length})',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: draft.products.length >= 15
                                  ? null
                                  : () => _product(),
                              icon: const Icon(Icons.add),
                              label: const Text('إضافة منتج'),
                            ),
                          ],
                        ),
                        const Text(
                          'أضف حتى 15 منتجًا كبداية، وتقدر تكمل وتعدل بعد تفعيل الحساب. صور JPG أو PNG أو WEBP، حتى 1 ميجا للصورة.',
                          style: TextStyle(
                            color: Color(0xFF707985),
                            height: 1.5,
                          ),
                        ),
                        if (draft.products.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  color: _orange,
                                  size: 40,
                                ),
                                SizedBox(height: 10),
                                Text('أضف أول منتج بصورته وسعره'),
                              ],
                            ),
                          ),
                        for (var i = 0; i < draft.products.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    draft.products[i].image.bytes,
                                    width: 62,
                                    height: 62,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        draft.products[i].name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        '${draft.products[i].price} ج / ${draft.products[i].unit}',
                                      ),
                                      if (draft.products[i].options.isNotEmpty)
                                        Text(
                                          '${draft.products[i].options.length} خيارات بيع',
                                          style: const TextStyle(
                                            color: Color(0xFF707985),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'تعديل المنتج',
                                  onPressed: () => _product(i),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'حذف المنتج',
                                  onPressed: () => setState(
                                    () => draft.products.removeAt(i),
                                  ),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                FilledButton.icon(
                  onPressed: _busy || _picking ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _orange,
                    minimumSize: const Size.fromHeight(54),
                  ),
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified_user_outlined),
                  label: Text(
                    _busy ? 'جارٍ إكمال الطلب…' : 'تأكيد البريد وإرسال الطلب',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class SignupProductScreen extends StatefulWidget {
  const SignupProductScreen({super.key, this.product, this.pickImage});
  final SignupProduct? product;
  final Future<SignupImage?> Function()? pickImage;
  @override
  State<SignupProductScreen> createState() => _SignupProductScreenState();
}

class _Option {
  _Option([Map<String, String>? value])
    : label = TextEditingController(text: value?['label']),
      price = TextEditingController(text: value?['price']);
  final TextEditingController label, price;
  void dispose() {
    label.dispose();
    price.dispose();
  }
}

class _SignupProductScreenState extends State<SignupProductScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name);
  late final _unit = TextEditingController(
    text: widget.product?.unit ?? 'قطعة',
  );
  late final _price = TextEditingController(text: widget.product?.price);
  late final _description = TextEditingController(
    text: widget.product?.description,
  );
  late final _options = (widget.product?.options ?? [])
      .map((o) => _Option(o))
      .toList();
  late SignupImage? _image = widget.product?.image;
  bool _picking = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _price.dispose();
    _description.dispose();
    for (final o in _options) {
      o.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() => _picking = true);
    try {
      final image = await (widget.pickImage ?? _pickImage)();
      if (image != null && mounted) setState(() => _image = image);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  String? _money(String? v) => signupPrice(v ?? '') == null
      ? 'اكتب سعرًا صحيحًا من 0.01 إلى 1000000 ج'
      : null;
  void _save() {
    if (!_form.currentState!.validate()) return;
    if (_image == null) {
      setState(() => _error = 'أضف صورة للمنتج.');
      return;
    }
    final labels = _options
        .map((o) => o.label.text.trim().toLowerCase())
        .toList();
    if (labels.toSet().length != labels.length) {
      setState(() => _error = 'اكتب اسمًا مختلفًا لكل اختيار.');
      return;
    }
    Navigator.pop(
      context,
      SignupProduct(
        name: _name.text.trim(),
        unit: _unit.text.trim(),
        price: signupPrice(_price.text)!,
        image: _image!,
        description: _description.text.trim(),
        options: _options
            .map(
              (o) => {
                'label': o.label.text.trim(),
                'price': signupPrice(o.price.text)!,
              },
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: Text(widget.product == null ? 'إضافة منتج' : 'تعديل المنتج'),
      ),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_image != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.memory(
                    _image!.bytes,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),
              OutlinedButton.icon(
                onPressed: _picking ? null : _pick,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(
                  _picking
                      ? 'جارٍ تحميل الصورة…'
                      : _image == null
                      ? 'إضافة صورة المنتج'
                      : 'تغيير الصورة',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _name,
                decoration: _field('اسم المنتج'),
                maxLength: 150,
                validator: (v) =>
                    (v ?? '').trim().length < 2 ? 'اكتب اسم المنتج' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _unit,
                decoration: _field('الوحدة الأساسية: كيلو / عبوة / قطعة'),
                maxLength: 40,
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'اكتب الوحدة' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _price,
                decoration: _field('السعر بالجنيه'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _money,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                decoration: _field('وصف المنتج (اختياري)'),
                maxLength: 2000,
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              const Text(
                'خيارات البيع',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const Text(
                'مثل نصف كيلو أو ربع كيلو، مع السعر الكامل لكل اختيار.',
              ),
              for (final option in _options)
                Padding(
                  key: ObjectKey(option),
                  padding: const EdgeInsets.only(top: 14),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: option.label,
                        decoration: _field('اسم الاختيار'),
                        maxLength: 60,
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'اكتب اسم الاختيار'
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: option.price,
                              decoration: _field('سعر الاختيار بالجنيه'),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: _money,
                            ),
                          ),
                          IconButton(
                            tooltip: 'حذف الاختيار',
                            onPressed: () => setState(() {
                              _options.remove(option);
                              option.dispose();
                            }),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              TextButton.icon(
                onPressed: _options.length >= 20
                    ? null
                    : () => setState(() => _options.add(_Option())),
                icon: const Icon(Icons.add),
                label: const Text('إضافة اختيار'),
              ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _picking ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _orange,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('حفظ المنتج في الطلب'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
