import 'package:flutter/material.dart';
import '../widget/partner_auth_scaffold.dart';
import 'partner_application_screen.dart';

class PartnerTypeScreen extends StatefulWidget {
  const PartnerTypeScreen({super.key});
  @override
  State<PartnerTypeScreen> createState() => _PartnerTypeScreenState();
}

class _PartnerTypeScreenState extends State<PartnerTypeScreen> {
  String? _type;
  @override
  Widget build(BuildContext context) => PartnerAuthScaffold(
    title: 'اختر نوع الشريك',
    description: 'كل شريك.. فرصة أكبر. اختر المجال المناسب لك.',
    children: [
      _choice(
        'delegate',
        'مندوب توصيل',
        'توصيل طلبات العملاء',
        Icons.delivery_dining_outlined,
      ),
      _choice(
        'vendor',
        'صاحب مطعم / متجر',
        'تقديم طلب انضمام لمتجرك',
        Icons.storefront_outlined,
      ),
      _choice(
        'profession',
        'صاحب مهنة / صنايعي',
        'تقديم خدمات مهنية للعملاء',
        Icons.handyman_outlined,
      ),
      const SizedBox(height: 20),
      const Text(
        'كل طلب انضمام بيخضع لمراجعة الإدارة قبل تفعيل الحساب.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xff737b86), height: 1.5),
      ),
      const SizedBox(height: 20),
      PartnerAuthButton(
        label: 'التالي',
        onPressed: _type == null
            ? null
            : () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => PartnerApplicationScreen(partnerType: _type!),
                ),
              ),
      ),
    ],
  );

  Widget _choice(String type, String title, String subtitle, IconData icon) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Material(
          color: _type == type ? const Color(0xfffff2e8) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: _type == type
                  ? const Color(0xfffd7201)
                  : const Color(0xffe6e8ec),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            onTap: () => setState(() => _type = type),
            leading: Icon(icon, color: const Color(0xfffd7201), size: 32),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(subtitle),
            trailing: Icon(
              _type == type ? Icons.check_circle : Icons.chevron_left,
              color: const Color(0xfffd7201),
            ),
          ),
        ),
      );
}
