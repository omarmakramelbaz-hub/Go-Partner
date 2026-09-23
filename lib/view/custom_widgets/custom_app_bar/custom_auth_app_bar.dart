import 'package:flutter/material.dart';

import '../../../helpers/images/app_images.dart';
import '../../../helpers/theme/app_colors.dart';
import '../custom_image/custom_image.dart';

class CustomAuthAppBar extends PreferredSize {
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

  CustomAuthAppBar(
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
  }) : super(
          preferredSize: Size.fromHeight(height),
          child: AppBar(
            elevation: elevation,
            scrolledUnderElevation: 0,
            backgroundColor: appBarColor ?? AppColor.whiteColor(context),
            surfaceTintColor: Colors.transparent,
            toolbarHeight: height,
            automaticallyImplyLeading: false,
            shadowColor: shadowColor,
            centerTitle: centerTitle ?? true,
            title: title ??
                const CustomImage(
                  path: AppImages.appIcon,
                  type: ImageType.asset,
                  height: 56,
                ),
            leading: leading ??
                (automaticallyImplyLeading && Navigator.canPop(context)
                    ? Padding(
                        padding: const EdgeInsets.all(11),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () => Navigator.maybePop(context),
                            borderRadius: BorderRadius.circular(14),
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
                              child: Icon(
                                Directionality.of(context) == TextDirection.rtl
                                    ? Icons.arrow_forward_rounded
                                    : Icons.arrow_back_rounded,
                                color: const Color(0xffFD7201),
                              ),
                            ),
                          ),
                        ),
                      )
                    : null),
            actions: actions ?? const [SizedBox(width: 16)],
            leadingWidth: leadingWidth ?? 64,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                borderRadius: borderRadius ?? BorderRadius.vertical(bottom: Radius.circular(radius)),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xfffff5ec), Color(0xffffffff)],
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
