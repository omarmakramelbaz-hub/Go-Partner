import 'package:flutter/material.dart';

import '../../../global/partner/partner_identity.dart';

class SettingButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final IconData icon;
  final bool destructive;
  const SettingButton({
    super.key,
    required this.title,
    required this.onTap,
    this.icon = Icons.settings_outlined,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xffD63B43) : PartnerIdentity.ink;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 57),
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: PartnerIdentity.border)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 21),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: PartnerIdentity.muted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
