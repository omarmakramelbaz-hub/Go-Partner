import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

import '../../../helpers/extension/context_extension.dart';
import '../../../helpers/theme/app_colors.dart';

class CustomOtpField extends StatefulWidget {
  final int length;
  final TextEditingController? controller;
  final void Function(String)? onCompleted;
  final double radius;

  const CustomOtpField({
    super.key,
    this.length = 4,
    this.controller,
    this.onCompleted,
    this.radius = 18,
  });

  @override
  State<CustomOtpField> createState() => _CustomOtpFieldState();
}

class _CustomOtpFieldState extends State<CustomOtpField> {
  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF171A1F);
    const orange = Color(0xffFD7201);

    PinTheme theme({
      Color border = const Color(0xffDADDE2),
      Color fill = Colors.white,
      Color text = navy,
      double width = 1,
      List<BoxShadow>? shadow,
    }) {
      return PinTheme(
        width: 66,
        height: 66,
        textStyle: TextStyle(
          fontSize: 22,
          color: text,
          fontWeight: FontWeight.w800,
          fontFamily: context.fontFamily(),
        ),
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: border, width: width),
          borderRadius: BorderRadius.circular(widget.radius),
          boxShadow: shadow,
        ),
      );
    }

    return Center(
      child: Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Pinput(
          length: widget.length,
          controller: widget.controller,
          defaultPinTheme: theme(
            shadow: [
              BoxShadow(
                color: navy.withOpacity(.045),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          focusedPinTheme: theme(
            border: orange,
            width: 1.5,
            fill: const Color(0xffFFFDFC),
            shadow: [
              BoxShadow(
                color: orange.withOpacity(.13),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          submittedPinTheme: theme(
            border: const Color(0xffFFD1AA),
            fill: const Color(0xffFFF8F2),
          ),
          errorPinTheme: theme(border: const Color(0xffE5484D)),
          errorBuilder: (errorText, pin) {
            if (errorText == null || errorText.isEmpty) return const SizedBox.shrink();
            return Align(
              alignment: context.getByLang(
                ar: AlignmentDirectional.centerEnd,
                en: AlignmentDirectional.centerStart,
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 8, left: 5, right: 5),
                child: Text(
                  errorText,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColor.redColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },
          validator: (s) {
            return s?.trim().length == widget.length
                ? null
                : context.apiTr(
                    ar: 'الكود مكون من ${widget.length} ارقام',
                    en: 'The code consists of ${widget.length} digits',
                  );
          },
          pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          onCompleted: widget.onCompleted,
        ),
      ),
    );
  }
}
