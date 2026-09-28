import '../../view/custom_widgets/popups/go_popups.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

import '../../view/custom_widgets/custom_loading/custom_loading.dart';
import '../routes/app_routers_import.dart';
import '../theme/app_colors.dart';

class NavigatorMethods {
  static String? currentRoute; // Track the current route globally.

  static void pushNamed(
    BuildContext context,
    String routeName, {
    dynamic arguments,
    Function(dynamic result)? onReturn,
  }) {
    if (_shouldNavigate(routeName)) {
      Navigator.pushNamed(context, routeName, arguments: arguments).then((result) {
        if (onReturn != null) {
          onReturn(result);
        }
      });
      _updateCurrentRoute(routeName);
    }
  }

  static void pop(BuildContext context) {
    Navigator.pop(context);
    currentRoute = null; // Reset current route if popping to an unknown route.
  }

  static void pushReplacementNamed(BuildContext context, String routeName, {dynamic arguments}) {
    if (_shouldNavigate(routeName)) {
      Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
      _updateCurrentRoute(routeName);
    }
  }

  static void pushNamedAndRemoveUntil(BuildContext context, String routeName, {dynamic arguments}) {
    Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false, arguments: arguments);
    _updateCurrentRoute(routeName);
  }

  static void showAppDialog(BuildContext context, Widget dialog, {bool willPop = true}) {
    showGoDialog(
      context: context,
      barrierDismissible: willPop,
      builder: (context) {
        return PopScope(canPop: willPop, child: dialog);
      },
    );
  }

  static void showAppBottomSheet(
    BuildContext context,
    Widget bottomSheet, {
    bool willPop = true,
    bool? isScrollControlled,
    bool enableDrag = true,
  }) {
    showGoModalBottomSheet(
      backgroundColor: Colors.transparent,
      elevation: 0,
      isScrollControlled: isScrollControlled ?? false,
      isDismissible: willPop,
      enableDrag: enableDrag,
      context: context,
      builder: (context) {
        return PopScope(canPop: willPop, child: bottomSheet);
      },
    );
  }

  static void loading({
    double size = 60,
    double radius = 30,
    double loadingSize = 30,
    Color? backgroundColor,
    Color? loadingColor,
  }) {
    FocusScope.of(AppRouters.navigatorKey.currentContext!).requestFocus(FocusNode());
    BotToast.showCustomLoading(
      toastBuilder: (cancelFunc) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColor.scaffoldColor(AppRouters.navigatorKey.currentContext!),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Center(
          child: CustomLoading(
            color: loadingColor ?? AppColor.mainAppColor(AppRouters.navigatorKey.currentContext!),
            size: loadingSize,
          ),
        ),
      ),
    );
  }

  static void loadingOff() {
    BotToast.closeAllLoading();
  }

  /// Helper: Checks if navigation is necessary.
  static bool _shouldNavigate(String routeName) {
    if (currentRoute == routeName) {
      debugPrint('Already on route: $routeName. Navigation skipped.');
      return false;
    }
    return true;
  }

  /// Helper: Updates the current route name.
  static void _updateCurrentRoute(String routeName) {
    currentRoute = routeName;
    debugPrint('Updated current route: $routeName');
  }
}
