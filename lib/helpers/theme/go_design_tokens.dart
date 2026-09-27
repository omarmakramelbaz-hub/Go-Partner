import 'package:flutter/material.dart';

/// Shared GO visual contract, taken from the existing GO Partner interface.
/// Keep this file identical in Go-Partner and Go-customer. Presentation only.
abstract final class GoDesign {
  static const orange = Color(0xFFFD7201);
  static const orangeEnd = Color(0xFFFF5900);
  static const orangeTint = Color(0xFFFFF1E5);
  static const ink = Color(0xFF171A1F);
  static const deepInk = ink;
  static const paper = Color(0xFFFFFFFF);
  static const canvas = Color(0xFFF8F9FB);
  static const segmented = Color(0xFFF4F5F7);
  static const muted = Color(0xFF7D8490);
  static const authMuted = Color(0xFF737B86);
  static const border = Color(0xFFE6E8EC);
  static const fieldBorder = Color(0xFFE3E6EA);
  static const success = Color(0xFF16A36A);
  static const danger = Color(0xFFE5484D);
  static const radius = 12.0;
  static const cardRadius = 22.0;
  static const sheetRadius = 30.0;
  static const dialogRadius = 28.0;
  static const pagePadding = 20.0;
  static const authPadding = 24.0;
  static const authMaxWidth = 420.0;
  static const controlHeight = 54.0;
  static const actionGradient = LinearGradient(
    begin: AlignmentDirectional.centerStart,
    end: AlignmentDirectional.centerEnd,
    colors: [orange, orangeEnd],
  );
  static const darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ink, Color(0xFF292D34)],
  );
  static const cardShadow = [
    BoxShadow(color: Color(0x08000000), blurRadius: 16, offset: Offset(0, 5)),
  ];
}
