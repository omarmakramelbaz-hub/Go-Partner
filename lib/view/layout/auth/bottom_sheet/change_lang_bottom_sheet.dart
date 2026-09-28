import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../custom_widgets/popups/go_popups.dart';

class ChangeLangBottomSheet extends StatefulWidget {
  const ChangeLangBottomSheet({super.key});
  @override
  State<ChangeLangBottomSheet> createState() => _LanguageState();
}

class _LanguageState extends State<ChangeLangBottomSheet> {
  bool busy = false;
  Future<void> select(String language) async {
    if (busy) return;
    setState(() => busy = true);
    await context.setLocale(Locale(language));
    await HiveMethods.updateLang(Locale(language));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => GoSheet(
    title: 'changeLanguage'.tr(),
    icon: Icons.language_rounded,
    busy: busy,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final language in ['ar', 'en'])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GoPopupChoice(
              label: language == 'ar' ? 'العربية' : 'English',
              subtitle: language == 'ar' ? 'Arabic' : 'الإنجليزية',
              leading: Text(language.toUpperCase()),
              selected: context.locale.languageCode == language,
              onTap: busy ? null : () => select(language),
            ),
          ),
      ],
    ),
  );
}
