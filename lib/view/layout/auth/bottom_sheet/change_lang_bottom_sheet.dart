import '../../../custom_widgets/popups/go_popups.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../custom_widgets/buttons/custom_button.dart';

class ChangeLangBottomSheet extends StatefulWidget {
  const ChangeLangBottomSheet({super.key});

  @override
  State<ChangeLangBottomSheet> createState() => _MenuBottomSheetWidgetState();
}

class _MenuBottomSheetWidgetState extends State<ChangeLangBottomSheet> {
  @override
  Widget build(BuildContext context) => GoSheet(title: AppLocaleKey.changeLanguage.tr(),
    icon: Icons.language_rounded,
    child: GoPopupChoice(label: 'العربية', subtitle: 'Arabic', selected: context.locale.languageCode == 'ar',
      leading: const Text('AR'), onTap: () {
        context.setLocale(const Locale('ar'));
        HiveMethods.updateLang(const Locale('ar'));
        Navigator.pop(context);
      }));
}
