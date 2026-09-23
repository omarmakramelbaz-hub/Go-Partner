import 'package:flutter/material.dart';

import '../extension/context_extension.dart';
import 'app_colors.dart';
import 'app_theme.dart';

ThemeData appThemeData(BuildContext context) {
  const navy = Color(0xFF171A1F);
  const orange = Color(0xffFD7201);
  const softText = Color(0xff7D8490);
  const border = Color(0xffE6E8EC);

  final brightness = AppTheme.getByTheme(context, light: Brightness.light, dark: Brightness.dark);

  return ThemeData(
    primaryColor: orange,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    useMaterial3: false,
    brightness: brightness,
    scaffoldBackgroundColor: AppColor.scaffoldColor(context),
    fontFamily: context.fontFamily(),
    splashColor: orange.withOpacity(.08),
    highlightColor: orange.withOpacity(.04),
    hintColor: softText,
    colorScheme: ColorScheme.fromSwatch().copyWith(
      primary: orange,
      secondary: navy,
      surface: Colors.white,
      brightness: brightness,
    ),
    appBarTheme: TextStyleTheme.appBar(context),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: border),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xffECEEF1),
      thickness: 1,
      space: 1,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      modalBackgroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      elevation: 18,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      hintStyle: TextStyle(color: softText.withOpacity(.72), fontSize: 15, fontWeight: FontWeight.w400),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xffDADDE2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: orange, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xffE5484D)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xffE5484D), width: 1.4),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: orange,
      unselectedLabelColor: softText,
      dividerColor: Colors.transparent,
      indicatorColor: orange,
      labelStyle: TextStyle(fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: orange,
      unselectedItemColor: Color(0xff9AA0AA),
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: orange,
      selectionColor: Color(0x33FD7201),
      selectionHandleColor: orange,
    ),
    buttonTheme: const ButtonThemeData(alignedDropdown: true),
    platform: TargetPlatform.iOS,
  );
}

class TextStyleTheme {
  static AppBarTheme appBar(BuildContext context) {
    return AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      foregroundColor: const Color(0xFF171A1F),
      iconTheme: const IconThemeData(color: Color(0xFF171A1F)),
      actionsIconTheme: const IconThemeData(color: Color(0xFF171A1F)),
      titleTextStyle: TextStyle(
        color: const Color(0xFF171A1F),
        fontSize: 20,
        fontWeight: FontWeight.w800,
        fontFamily: context.fontFamily(),
      ),
    );
  }
}

List<BoxShadow> appShadow = [
  BoxShadow(
    color: const Color(0xFF171A1F).withOpacity(.08),
    offset: const Offset(0, 10),
    blurRadius: 28,
  ),
];
