import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../helpers/theme/go_design_tokens.dart';

enum ToastType { success, error, offline, warning, help }

class CustomToast extends StatelessWidget {
  const CustomToast({
    super.key,
    required this.type,
    required this.message,
    this.title,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.onClose,
    this.onTap,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });
  final ToastType type;
  final String message;
  final String? title, icon, actionLabel;
  final Color? backgroundColor, textColor;
  final VoidCallback? onClose, onTap, onAction;
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final accent = switch (type) {
      ToastType.error => GoDesign.danger,
      ToastType.warning => const Color(0xFFB8780B),
      ToastType.offline => GoDesign.authMuted,
      _ => GoDesign.orange,
    };
    final symbol = switch (type) {
      ToastType.success => Icons.check_circle_outline_rounded,
      ToastType.error => Icons.error_outline_rounded,
      ToastType.offline => Icons.wifi_off_rounded,
      ToastType.warning => Icons.warning_amber_rounded,
      ToastType.help => Icons.info_outline_rounded,
    };
    final heading = title?.trim().isNotEmpty == true
        ? title!
        : switch (type) {
            ToastType.success => ar ? 'تم بنجاح' : 'Success',
            ToastType.error =>
              ar ? 'تعذر إتمام العملية' : 'Something went wrong',
            ToastType.offline =>
              ar ? 'لا يوجد اتصال بالإنترنت' : 'No internet connection',
            ToastType.warning => ar ? 'تنبيه' : 'Notice',
            ToastType.help => ar ? 'معلومة' : 'Information',
          };
    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Center(
        heightFactor: 1,
        child: Container(
          width: 560,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: GoDesign.paper,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: GoDesign.border),
            boxShadow: GoDesign.cardShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .09),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: icon == null
                          ? Icon(symbol, color: accent, size: 23)
                          : SvgPicture.asset(
                              icon!,
                              colorFilter: ColorFilter.mode(
                                accent,
                                BlendMode.srcIn,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            heading,
                            style: const TextStyle(
                              color: GoDesign.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: const TextStyle(
                              color: GoDesign.authMuted,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                          if (onAction != null &&
                              actionLabel?.isNotEmpty == true)
                            TextButton.icon(
                              onPressed: onAction,
                              icon: Icon(
                                actionIcon ?? Icons.arrow_forward_rounded,
                                size: 18,
                              ),
                              label: Text(actionLabel!),
                            ),
                        ],
                      ),
                    ),
                    if (onClose != null)
                      IconButton(
                        onPressed: onClose,
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        icon: const Icon(Icons.close_rounded, size: 20),
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
