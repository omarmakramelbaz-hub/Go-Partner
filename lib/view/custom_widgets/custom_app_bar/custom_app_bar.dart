import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../global/partner/partner_identity.dart';

/// Dark header and rounded white content edge from the GO Partner reference.
class CustomAppBar extends PreferredSize {
  CustomAppBar(
    BuildContext context, {
    super.key,
    double height = 76,
    double radius = 24,
    double elevation = 0,
    Widget? leading,
    List<Widget>? actions,
    Widget? title,
    Color? appBarColor,
    Color? shadowColor,
    bool? centerTitle,
    PreferredSizeWidget? bottom,
    double? leadingWidth,
    bool automaticallyImplyLeading = true,
    BorderRadiusGeometry? borderRadius,
    double? leadingPadding,
  }) : super(
         preferredSize: Size.fromHeight(height),
         child: AppBar(
           backgroundColor: appBarColor ?? PartnerIdentity.ink,
           surfaceTintColor: Colors.transparent,
           foregroundColor: Colors.white,
           systemOverlayStyle: SystemUiOverlayStyle.light,
           elevation: elevation,
           scrolledUnderElevation: 0,
           toolbarHeight: height - (bottom == null ? 12 : 0),
           centerTitle: centerTitle ?? true,
           titleSpacing: 12,
           automaticallyImplyLeading: automaticallyImplyLeading,
           leading: leading,
           leadingWidth: leadingWidth,
           actions: actions,
           title: title is Text && title.data != null
               ? Text(
                   title.data!,
                   maxLines: 2,
                   overflow: TextOverflow.ellipsis,
                   style: (title.style ?? const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)).copyWith(
                     color: Colors.white,
                   ),
                 )
               : title,
           iconTheme: const IconThemeData(color: Colors.white),
           bottom:
               bottom ??
               PreferredSize(
                 preferredSize: const Size.fromHeight(12),
                 child: Container(
                   height: 12,
                   decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
                   ),
                 ),
               ),
         ),
       );
}
