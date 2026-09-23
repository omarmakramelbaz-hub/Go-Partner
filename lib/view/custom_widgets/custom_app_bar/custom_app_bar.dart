import 'package:flutter/material.dart';

import '../../../helpers/theme/app_colors.dart';

class CustomAppBar extends PreferredSize {
  final double height;
  final double radius;
  final double elevation;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget? title;
  final Color? appBarColor;
  final Color? shadowColor;
  final bool? centerTitle;
  final PreferredSizeWidget? bottom;
  final double? leadingWidth;
  final bool automaticallyImplyLeading;
  final BuildContext context;
  final BorderRadiusGeometry? borderRadius;
  final double? leadingPadding;

  CustomAppBar(
    this.context, {
    super.key,
    this.height = 92,
    this.radius = 24,
    this.elevation = 0,
    this.leading,
    this.actions,
    this.title,
    this.appBarColor,
    this.centerTitle,
    this.bottom,
    this.leadingWidth,
    this.shadowColor,
    this.automaticallyImplyLeading = true,
    this.borderRadius,
    this.leadingPadding,
  }) : super(
          preferredSize: Size.fromHeight(height),
          child: AppBar(
            elevation: elevation,
            scrolledUnderElevation: 0,
            backgroundColor: appBarColor ?? AppColor.whiteColor(context),
            surfaceTintColor: Colors.transparent,
            toolbarHeight: height,
            automaticallyImplyLeading: false,
            shadowColor: shadowColor ?? const Color(0xFF171A1F).withOpacity(.08),
            centerTitle: centerTitle ?? false,
            titleSpacing: 14,
            title: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: title ?? const SizedBox(),
            ),
            leading: leading ??
                (automaticallyImplyLeading && Navigator.canPop(context)
                    ? Padding(
                        padding: EdgeInsets.only(
                          top: 10,
                          bottom: leadingPadding == null ? 10 : (leadingPadding! > 24 ? 18 : leadingPadding!),
                          left: 6,
                          right: 6,
                        ),
                        child: _PremiumBackButton(context: context),
                      )
                    : null),
            actions: actions,
            leadingWidth: leadingWidth ?? 62,
            flexibleSpace: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius ?? BorderRadius.vertical(bottom: Radius.circular(radius)),
                  gradient: appBarColor == null
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xfffffbf7), Color(0xffffffff)],
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF171A1F).withOpacity(.045),
                      blurRadius: 18,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: borderRadius ?? BorderRadius.vertical(bottom: Radius.circular(radius)),
            ),
            bottom: bottom,
          ),
        );
}

class _PremiumBackButton extends StatelessWidget {
  const _PremiumBackButton({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.maybePop(this.context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xffECEEF1)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF171A1F).withOpacity(.07),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            Directionality.of(context) == TextDirection.rtl
                ? Icons.arrow_forward_rounded
                : Icons.arrow_back_rounded,
            color: const Color(0xffFD7201),
            size: 24,
          ),
        ),
      ),
    );
  }
}
