import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/utils/url_launcher_methods.dart';

class MobileAndEmailContactUsWidget extends StatelessWidget {
  final String mobile;
  final String email;

  const MobileAndEmailContactUsWidget({super.key, required this.mobile, required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ContactTile(
          icon: Icons.phone_in_talk_rounded,
          label: AppLocaleKey.mobileNumber.tr(),
          value: mobile,
          onTap: () => UrlLauncherMethods.makePhoneCall(mobile),
        ),
        const SizedBox(height: 10),
        _ContactTile(
          icon: Icons.email_outlined,
          label: AppLocaleKey.email.tr(),
          value: email,
          onTap: () => UrlLauncherMethods.makeMailMessage(email),
        ),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF171A1F);
    const softText = Color(0xff7D8490);
    const orange = Color(0xffFD7201);

    return Material(
      color: const Color(0xffFAFAFB),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xffECEEF1)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xffFFF0E3),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: orange, size: 22),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(color: softText, fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: navy, fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_outward_rounded, color: orange, size: 19),
            ],
          ),
        ),
      ),
    );
  }
}
