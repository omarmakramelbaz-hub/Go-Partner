import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../helpers/networking/api_helper.dart';
import '../../../../helpers/networking/urls.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';

class PartnerServiceRequestsScreen extends StatefulWidget {
  const PartnerServiceRequestsScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<PartnerServiceRequestsScreen> createState() => _PartnerServiceRequestsScreenState();
}

class _PartnerServiceRequestsScreenState extends State<PartnerServiceRequestsScreen> {
  static const _orange = Color(0xFFFD7201);
  static const _navy = Color(0xFF171A1F);
  static const _muted = Color(0xFF7D8490);
  static const _bg = Colors.white;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final response = await ApiHelper.instance.get(Urls.delegateServiceRequests, queryParameters: {'status': 'current'});

    if (!mounted) return;
    if (response.state == ResponseState.complete) {
      final raw = response.data is Map ? response.data['data'] : null;
      setState(() {
        _items = raw is List ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : [];
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = response.data is Map
            ? response.data['message']?.toString() ?? 'تعذر تحميل الطلبات.'
            : 'تعذر تحميل الطلبات.';
      });
    }
  }

  Future<void> _update(int id, String status) async {
    final response = await ApiHelper.instance.post(Urls.updateDelegateServiceRequest(id), body: {'status': status});

    if (!mounted) return;
    if (response.state == ResponseState.complete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'accepted'
                ? 'تم قبول الطلب.'
                : status == 'completed'
                ? 'تم إنهاء الطلب.'
                : 'تم رفض الطلب.',
          ),
        ),
      );
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.data is Map ? response.data['message']?.toString() ?? 'تعذر تحديث الطلب.' : 'تعذر تحديث الطلب.',
          ),
        ),
      );
    }
  }

  Future<void> _openMap(Map location) async {
    final lat = location['lat'];
    final lng = location['lng'];
    if (lat == null || lng == null) return;
    final uri = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: widget.embedded ? null : CustomAppBar(context, title: const Text('طلبات الخدمات')),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Color(0xFF292D33), Color(0xFF101216)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      radius: 27,
                      backgroundColor: Color(0x22FFFFFF),
                      child: Icon(Icons.handyman_rounded, color: _orange, size: 30),
                    ),
                    SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'طلبات العملاء لمهنتك',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'ستظهر هنا الطلبات المرسلة لك بكل تفاصيل العميل والموقع والصور.',
                            style: TextStyle(color: Color(0xFFC8D6E0), height: 1.45, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 70),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _state(_error!, true)
              else if (_items.isEmpty)
                _state('لا توجد طلبات خدمات جديدة حاليًا.', false)
              else
                ..._items.map(_requestCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _state(String text, bool retry) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, color: _orange, size: 50),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _navy, height: 1.5, fontWeight: FontWeight.w700),
          ),
          if (retry) ...[const SizedBox(height: 10), TextButton(onPressed: _load, child: const Text('إعادة المحاولة'))],
        ],
      ),
    );
  }

  Widget _requestCard(Map<String, dynamic> item) {
    final status = item['status']?.toString() ?? 'pending';
    final profession = item['profession'] is Map
        ? (item['profession']['ar']?.toString() ?? item['profession_key']?.toString())
        : item['profession_key']?.toString();
    final customer = item['customer'] is Map ? Map<String, dynamic>.from(item['customer']) : <String, dynamic>{};
    final location = item['location'] is Map ? Map<String, dynamic>.from(item['location']) : <String, dynamic>{};
    final photos = item['photos'] is List ? item['photos'] as List : const [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFFE7EAED)),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(color: const Color(0xFFFFF1E7), borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.build_circle_outlined, color: _orange),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profession ?? 'طلب خدمة',
                      style: const TextStyle(color: _navy, fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      customer['name']?.toString() ?? 'عميل GO',
                      style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 14),
          _info(Icons.notes_rounded, item['description']?.toString() ?? '—'),
          const SizedBox(height: 8),
          _info(Icons.phone_outlined, customer['mobile']?.toString() ?? '—'),
          const SizedBox(height: 8),
          _info(
            Icons.location_on_outlined,
            location['address']?.toString().isNotEmpty == true
                ? location['address'].toString()
                : 'الموقع مرفق بالإحداثيات',
          ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 7),
                itemBuilder: (_, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.network(
                    photos[index].toString(),
                    width: 82,
                    height: 82,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 82,
                      height: 82,
                      color: const Color(0xFFF2F3F4),
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _openMap(location),
            icon: const Icon(Icons.map_outlined),
            label: const Text('فتح موقع العميل على الخريطة'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _orange,
              side: const BorderSide(color: Color(0xFFFFCBA9)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
          const SizedBox(height: 8),
          if (status == 'pending')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _update(item['id'] as int, 'declined'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('رفض', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => _update(item['id'] as int, 'accepted'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('قبول الطلب', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            )
          else if (status == 'accepted')
            FilledButton.icon(
              onPressed: () => _update(item['id'] as int, 'completed'),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('تم تنفيذ الخدمة', style: TextStyle(fontWeight: FontWeight.w900)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF178C4B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _orange, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: _navy, height: 1.45, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final accepted = status == 'accepted';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: accepted ? const Color(0xFFEAF8EF) : const Color(0xFFFFF1E7),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        accepted ? 'مقبول' : 'جديد',
        style: TextStyle(
          color: accepted ? const Color(0xFF178C4B) : _orange,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
