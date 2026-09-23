import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../helpers/images/app_images.dart';

enum ToastType { success, error, offline, warning, help }

class CustomToast extends StatelessWidget {
  final ToastType type;
  final String? title;
  final String? icon;
  final String message;

  /// Kept for backwards compatibility with existing callers.
  /// Go Drive notifications now deliberately use one unified brand palette.
  final Color? backgroundColor;
  final Color? textColor;

  const CustomToast({
    super.key,
    required this.type,
    this.title,
    required this.message,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  static const _orange = Color(0xffFD7201);
  static const _navy = Color(0xFF171A1F);
  static const _softText = Color(0xff667384);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth * .92).clamp(280.0, 520.0).toDouble();

    return Container(
      width: cardWidth,
      constraints: const BoxConstraints(minHeight: 68),
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 2),
      padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            Color(0xFAFFFBF7),
            Color(0xF7FFF0E2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0x66FD7201),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: _orange.withOpacity(.16),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
          BoxShadow(
            color: _navy.withOpacity(.055),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _orange.withOpacity(.105),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _orange.withOpacity(.13)),
            ),
            child: SvgPicture.asset(
              icon ?? _icons(),
              width: 22,
              height: 22,
              colorFilter: const ColorFilter.mode(
                _orange,
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
                if (title != null && title!.trim().isNotEmpty) ...[
                  Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 14.5,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: title == null ? _navy : _softText,
                    fontSize: 13.5,
                    height: 1.38,
                    fontWeight: title == null ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _orange.withOpacity(.85),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _orange.withOpacity(.30),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _icons() {
    switch (type) {
      case ToastType.success:
        return AppImages.success;
      case ToastType.error:
        return AppImages.error;
      case ToastType.offline:
        return AppImages.offlineIcon;
      case ToastType.warning:
        return AppImages.warning;
      case ToastType.help:
        return AppImages.help;
    }
  }
}
