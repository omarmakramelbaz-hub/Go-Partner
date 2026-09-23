import 'dart:ui' as ui;

import 'package:country_picker/country_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import '../../../helpers/extension/context_extension.dart';
import '../../../helpers/theme/app_colors.dart';
import '../../../helpers/theme/app_text_style.dart';

enum FormFieldBorder { underLine, outLine, none }

class CustomFormField extends StatefulWidget {
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool isPassword;
  final String? hintText;
  final int? maxLines;
  final void Function()? onTap;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final double radius;
  final Color? fillColor;
  final Color? focusColor;
  final Color? unFocusColor;
  final Color? passwordColor;
  final String? title;
  final String? otherSideTitle;
  final ui.TextDirection? textDirection;
  final Country? country;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(Country)? onCountrySelect;
  final FormFieldBorder formFieldBorder;
  final TextStyle? titleStyle;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final int? maxLength;
  final AutovalidateMode? autovalidateMode;
  final bool hasShadow;
  final Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? contentPadding;

  const CustomFormField({
    super.key,
    this.controller,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.isPassword = false,
    this.hintText,
    this.maxLines = 1,
    this.onTap,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.radius = 18,
    this.fillColor,
    this.focusColor,
    this.unFocusColor,
    this.title,
    this.textDirection,
    this.otherSideTitle,
    this.country,
    this.passwordColor,
    this.formFieldBorder = FormFieldBorder.outLine,
    this.inputFormatters,
    this.onCountrySelect,
    this.titleStyle,
    this.textStyle,
    this.hintStyle,
    this.maxLength,
    this.autovalidateMode,
    this.hasShadow = true,
    this.focusNode,
    this.onFieldSubmitted,
    this.contentPadding,
  });

  @override
  State<CustomFormField> createState() => _CustomFormFieldState();
}

class _CustomFormFieldState extends State<CustomFormField> {
  bool _obscureText = true;
  bool _isFocus = false;
  final FocusNode _focusNode = FocusNode();

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _focusNode;

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode.addListener(_handleFocus);
  }

  @override
  void didUpdateWidget(covariant CustomFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _focusNode).removeListener(_handleFocus);
      _effectiveFocusNode.addListener(_handleFocus);
    }
  }

  void _handleFocus() {
    if (!mounted) return;
    setState(() => _isFocus = _effectiveFocusNode.hasFocus);
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocus);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF171A1F);
    const orange = Color(0xffFD7201);

    final titleStyle = widget.titleStyle ??
        AppTextStyle.formTitleStyle(context).copyWith(
          color: navy,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        );

    final field = Directionality(
      textDirection: widget.textDirection ?? (context.isRTL() ? ui.TextDirection.rtl : ui.TextDirection.ltr),
      child: TextFormField(
        onFieldSubmitted: widget.onFieldSubmitted,
        focusNode: _effectiveFocusNode,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        controller: widget.controller,
        onChanged: widget.onChanged,
        validator: widget.validator,
        onTap: widget.onTap,
        readOnly: widget.readOnly,
        keyboardType: widget.keyboardType,
        obscureText: widget.isPassword ? _obscureText : false,
        style: widget.textStyle ??
            AppTextStyle.textFormStyle(context).copyWith(
              color: navy,
              fontWeight: FontWeight.w600,
            ),
        autovalidateMode: widget.autovalidateMode ?? AutovalidateMode.onUserInteraction,
        maxLines: widget.maxLines,
        cursorColor: widget.focusColor ?? orange,
        inputFormatters: widget.inputFormatters,
        maxLength: widget.maxLength,
        decoration: InputDecoration(
          counterText: widget.maxLength == null ? null : '',
          hintMaxLines: 2,
          hintText: widget.hintText,
          hintStyle: widget.hintStyle ??
              AppTextStyle.hintStyle(context).copyWith(
                color: const Color(0xffAEB3BA),
                fontSize: 15,
              ),
          fillColor: widget.fillColor ??
              (widget.formFieldBorder == FormFieldBorder.underLine
                  ? Colors.transparent
                  : AppColor.textFormFillColor(context)),
          filled: true,
          border: _border(color: widget.unFocusColor ?? AppColor.textFormBorderColor(context)),
          disabledBorder: _border(color: const Color(0xffECEEF1)),
          focusedBorder: _border(color: widget.focusColor ?? orange, width: 1.4),
          enabledBorder: _border(color: widget.unFocusColor ?? AppColor.textFormBorderColor(context)),
          errorBorder: _border(color: const Color(0xffE5484D)),
          focusedErrorBorder: _border(color: const Color(0xffE5484D), width: 1.4),
          contentPadding: widget.contentPadding ?? const EdgeInsets.symmetric(vertical: 17, horizontal: 15),
          prefixIcon: _prefixIcon(context),
          suffixIcon: _suffixIcon(context),
        ),
      ),
    );

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null || widget.otherSideTitle != null) ...[
            Row(
              children: [
                if (widget.title != null) Expanded(child: Text(widget.title!, style: titleStyle)),
                if (widget.otherSideTitle != null) Text(widget.otherSideTitle!, style: titleStyle),
              ],
            ),
            const Gap(10),
          ],
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              boxShadow: widget.hasShadow && widget.formFieldBorder == FormFieldBorder.outLine
                  ? [
                      BoxShadow(
                        color: _isFocus ? orange.withOpacity(.10) : navy.withOpacity(.045),
                        blurRadius: _isFocus ? 18 : 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: field,
          ),
        ],
      ),
    );
  }

  Widget? _prefixIcon(BuildContext context) {
    if (widget.country != null && context.locale == const Locale('en')) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.prefixIcon ?? const SizedBox(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '${widget.country?.flagEmoji}  +${widget.country?.phoneCode}',
              style: widget.textStyle ?? AppTextStyle.textFormStyle(context).copyWith(fontWeight: FontWeight.w700),
              textDirection: ui.TextDirection.ltr,
            ),
          ),
        ],
      );
    }
    return widget.prefixIcon;
  }

  Widget? _suffixIcon(BuildContext context) {
    if (widget.country != null && context.locale == const Locale('ar')) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '${widget.country?.flagEmoji}  +${widget.country?.phoneCode}',
              style: widget.textStyle ?? AppTextStyle.textFormStyle(context).copyWith(fontWeight: FontWeight.w700),
              textDirection: ui.TextDirection.ltr,
            ),
          ),
          widget.suffixIcon ?? const SizedBox(),
        ],
      );
    }
    if (widget.isPassword) {
      return InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _obscureText = !_obscureText),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            _obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            size: 21,
            color: widget.passwordColor ?? AppColor.hintColor(context),
          ),
        ),
      );
    }
    return widget.suffixIcon;
  }

  InputBorder _border({required Color color, double width = 1}) {
    switch (widget.formFieldBorder) {
      case FormFieldBorder.outLine:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.radius),
          borderSide: BorderSide(color: color, width: width),
        );
      case FormFieldBorder.underLine:
        return UnderlineInputBorder(borderSide: BorderSide(color: color, width: width));
      case FormFieldBorder.none:
        return InputBorder.none;
    }
  }
}
