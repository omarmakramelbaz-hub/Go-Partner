import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material;

import '../../../helpers/theme/go_design_tokens.dart';

/// One popup presentation contract in both GO applications. These wrappers
/// preserve route results, dismissibility, navigators and form ownership.
class GoPopupTheme extends StatelessWidget {
  const GoPopupTheme({super.key, required this.child});
  final Widget child;

  static ThemeData data(BuildContext context) {
    final base = Theme.of(context);
    final font = base.textTheme.bodyMedium?.fontFamily;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    final primary = FilledButton.styleFrom(
      backgroundColor: GoDesign.orange,
      foregroundColor: Colors.white,
      minimumSize: const Size(48, 52),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: shape,
      elevation: 0,
      textStyle: TextStyle(
        fontFamily: font,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: GoDesign.orange,
        onPrimary: Colors.white,
        surface: GoDesign.paper,
        onSurface: GoDesign.ink,
        error: GoDesign.danger,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: GoDesign.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        barrierColor: const Color(0x990E1219),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GoDesign.dialogRadius),
        ),
        constraints: const BoxConstraints(minWidth: 320, maxWidth: 440),
        titleTextStyle: TextStyle(
          fontFamily: font,
          color: GoDesign.ink,
          fontSize: 21,
          fontWeight: FontWeight.w800,
          height: 1.4,
        ),
        contentTextStyle: TextStyle(
          fontFamily: font,
          color: GoDesign.authMuted,
          fontSize: 15,
          height: 1.6,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: GoDesign.paper,
        modalBackgroundColor: GoDesign.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        constraints: BoxConstraints(maxWidth: 560),
        dragHandleColor: GoDesign.border,
        dragHandleSize: Size(38, 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(GoDesign.sheetRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: GoDesign.canvas,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: TextStyle(
          fontFamily: font,
          color: GoDesign.muted,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: GoDesign.fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: GoDesign.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: GoDesign.orange, width: 1.5),
        ),
        errorMaxLines: 3,
      ),
      filledButtonTheme: FilledButtonThemeData(style: primary),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primary),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GoDesign.ink,
          side: const BorderSide(color: GoDesign.border),
          minimumSize: const Size(48, 48),
          shape: shape,
          textStyle: TextStyle(
            fontFamily: font,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: GoDesign.authMuted,
          minimumSize: const Size(48, 48),
          shape: shape,
          textStyle: TextStyle(
            fontFamily: font,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: GoDesign.ink,
          minimumSize: const Size(44, 44),
        ),
      ),
      dividerColor: GoDesign.border,
    );
  }

  @override
  Widget build(BuildContext context) =>
      Theme(data: data(context), child: child);
}

Future<T?> showGoDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  Color? barrierColor,
  String? barrierLabel,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
}) => material.showDialog<T>(
  context: context,
  barrierDismissible: barrierDismissible,
  useSafeArea: useSafeArea,
  useRootNavigator: useRootNavigator,
  barrierColor: barrierColor ?? const Color(0x990E1219),
  barrierLabel: barrierLabel,
  routeSettings: routeSettings,
  anchorPoint: anchorPoint,
  builder: (context) => GoPopupTheme(child: Builder(builder: builder)),
);

Future<T?> showGoModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useSafeArea = true,
  bool useRootNavigator = false,
  bool? showDragHandle,
  Color? backgroundColor,
  Color? barrierColor,
  double? elevation,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
}) => material.showModalBottomSheet<T>(
  context: context,
  isScrollControlled: isScrollControlled,
  isDismissible: isDismissible,
  enableDrag: enableDrag,
  useSafeArea: useSafeArea,
  useRootNavigator: useRootNavigator,
  showDragHandle: showDragHandle ?? false,
  backgroundColor: Colors.transparent,
  elevation: 0,
  barrierColor: barrierColor ?? const Color(0x990E1219),
  // All app-owned sheets use this outer silhouette, including custom map and
  // draggable sheets. Their content retains its own scrolling/controller.
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(GoDesign.sheetRadius),
    ),
  ),
  clipBehavior: Clip.antiAlias,
  constraints: constraints ?? const BoxConstraints(maxWidth: 560),
  routeSettings: routeSettings,
  transitionAnimationController: transitionAnimationController,
  builder: (context) => GoPopupTheme(
    child: Material(
      color: backgroundColor ?? GoDesign.paper,
      child: Builder(builder: builder),
    ),
  ),
);

class GoPopupHeader extends StatelessWidget {
  const GoPopupHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.tune_rounded,
    this.onClose,
    this.dark = false,
  });
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onClose;
  final bool dark;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Center(
        child: Container(
          width: 38,
          height: 4,
          decoration: BoxDecoration(
            color: dark ? Colors.white24 : GoDesign.border,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      const SizedBox(height: 20),
      Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: GoDesign.actionGradient,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.white, size: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: dark ? Colors.white : GoDesign.ink,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: onClose,
            style: IconButton.styleFrom(
              backgroundColor: dark ? Colors.white12 : GoDesign.canvas,
              foregroundColor: dark ? Colors.white : GoDesign.ink,
              minimumSize: const Size(44, 44),
            ),
            icon: const Icon(Icons.close_rounded, size: 21),
          ),
        ],
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 12),
        Text(
          subtitle!,
          style: TextStyle(
            color: dark ? Colors.white70 : GoDesign.authMuted,
            fontSize: 13,
            height: 1.6,
          ),
        ),
      ],
    ],
  );
}

class GoSheet extends StatelessWidget {
  const GoSheet({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon = Icons.tune_rounded,
    this.dark = false,
    this.busy = false,
    this.includeKeyboardInset = false,
    this.onClose,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final IconData icon;
  final bool dark, busy, includeKeyboardInset;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final keyboard = includeKeyboardInset
          ? MediaQuery.viewInsetsOf(context).bottom
          : 0.0;
      final available = constraints.maxHeight.isFinite
          ? constraints.maxHeight
          : MediaQuery.sizeOf(context).height * .9;
      return Padding(
        padding: EdgeInsets.only(bottom: keyboard),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: (available - keyboard).clamp(0.0, double.infinity),
            ),
            child: GoPopupTheme(
              child: Material(
                color: dark ? GoDesign.ink : GoDesign.paper,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(GoDesign.sheetRadius),
                ),
                clipBehavior: Clip.antiAlias,
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GoPopupHeader(
                          title: title,
                          subtitle: subtitle,
                          icon: icon,
                          dark: dark,
                          onClose: busy
                              ? null
                              : (onClose ?? () => Navigator.pop(context)),
                        ),
                        const SizedBox(height: 24),
                        child,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class GoPopupChoice extends StatelessWidget {
  const GoPopupChoice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.subtitle,
  });
  final String label;
  final String? subtitle;
  final Widget? leading;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    checked: selected,
    inMutuallyExclusiveGroup: true,
    child: Material(
      color: selected ? GoDesign.orangeTint : GoDesign.canvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? GoDesign.orange : GoDesign.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              if (leading != null) ...[
                SizedBox(width: 30, height: 30, child: Center(child: leading)),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: GoDesign.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: GoDesign.authMuted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                size: 21,
                color: selected ? GoDesign.orange : const Color(0xFFBEC4CC),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class GoPopupPrimaryButton extends StatelessWidget {
  const GoPopupPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon = Icons.arrow_forward_rounded,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData icon;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: GoDesign.actionGradient,
      borderRadius: BorderRadius.circular(16),
    ),
    child: FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white,
        shadowColor: Colors.transparent,
        minimumSize: const Size(double.infinity, 54),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(icon, size: 20),
              ],
            ),
    ),
  );
}
