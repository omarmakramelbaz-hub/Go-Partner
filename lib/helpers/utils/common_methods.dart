import '../../view/custom_widgets/popups/go_popups.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../view/custom_widgets/buttons/custom_button.dart';
import '../../view/custom_widgets/custom_select/custom_select_item.dart';
import '../../view/custom_widgets/custom_toast/custom_toast.dart';
import '../../view/layout/auth/controller/auth_controller.dart';
import '../../view/layout/my_account/screen/personal_information_delgate_screen.dart';
import '../enum/gender_enum.dart';
import '../extension/context_extension.dart';
import '../hive/hive_methods.dart';
import '../locale/app_locale_key.dart';
import '../networking/api_helper.dart';
import '../routes/app_routers_import.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_style.dart';
import 'navigator_methods.dart';

class CommonMethods {
  static void showAlertDialog({String? title, required String message}) {
    showGoDialog(context: AppRouters.navigatorKey.currentContext!, barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: title == null ? null : Text(title),
        content: Text(message),
        actions: [FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text('ok'.tr()))],
      ));
  }

  static void showChooseDialog(BuildContext context, {String? title, required String message, required VoidCallback onPressed}) {
    showGoDialog(context: context, barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: title == null ? null : Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('no'.tr())),
          FilledButton(onPressed: onPressed, child: Text('yes'.tr())),
        ],
      ));
  }

  static void showToast({
    required String message,
    String? title,
    String? icon,
    ToastType type = ToastType.success,
    Color? backgroundColor,
    Color? textColor,
    int seconds = 3,
  }) {
    BotToast.showCustomText(
      duration: Duration(seconds: seconds),
      toastBuilder: (cancelFunc) => CustomToast(
        type: type,
        title: title,
        message: message,
        backgroundColor: backgroundColor,
        icon: icon,
        textColor: textColor,
      ),
    );
  }

  static void showError({
    ApiResponse? apiResponse,
    required String message,
    String? title,
    String? icon,
    Color? backgroundColor,
    Color? textColor,
    int seconds = 3,
  }) {
    BotToast.showCustomText(
      duration: Duration(seconds: seconds),
      toastBuilder: (context) => CustomToast(
        title: title,
        message: message,
        type: apiResponse?.state == ResponseState.offline ? ToastType.offline : ToastType.error,
        backgroundColor: backgroundColor,
        icon: icon,
        textColor: textColor,
      ),
    );
  }

  static GenderEnum setGenderValue(String gender) {
    if (gender == 'male') {
      return GenderEnum.male;
    } else {
      return GenderEnum.female;
    }
  }

  static Future<bool> hasConnection() async {
    // Browser connectivity detection is not equivalent to Android/iOS.
    // The web implementation can report ethernet/other states, and treating
    // anything except mobile/wifi as offline prevents every API call.
    // Let the actual HTTP request determine reachability in web previews.
    if (kIsWeb) return true;

    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.any((result) => result != ConnectivityResult.none);
  }

  static List<CustomSelectItem> dropdownMenuItems = [
    ...List.generate(
      20,
      (index) => {
        'id': index,
        'value': AppRouters.navigatorKey.currentContext!.apiTr(ar: 'العنصر ${index + 1}', en: 'The item ${index + 1}'),
      },
    ),
  ].map((e) => CustomSelectItem(value: int.tryParse(e['id'].toString()), name: e['value']?.toString() ?? '')).toList();

  static void changeLanguage(BuildContext context, {required VoidCallback onTap}) {
    showGoModalBottomSheet<void>(context: context,
      builder: (context) => GoSheet(title: tr(AppLocaleKey.language), icon: Icons.language_rounded,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final language in ['ar', 'en']) Padding(padding: const EdgeInsets.only(bottom: 10),
            child: GoPopupChoice(label: language == 'ar' ? 'العربية' : 'English',
              selected: context.locale.languageCode == language,
              onTap: () {
                HiveMethods.updateLang(Locale(language));
                context.setLocale(Locale(language));
                onTap.call();
                MyApp.setMyAppState(context);
                Navigator.pop(context);
              })),
        ])));
  }

  static bool endScroll(ScrollEndNotification t, VoidCallback onEnd) {
    if (t.metrics.pixels > 0 && t.metrics.atEdge) {
      onEnd.call();
    }
    return true;
  }

  static void showCompleteInfoDialog({required BuildContext context}) {
    showGoDialog(
      useSafeArea: true,
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: AppColor.whiteColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: PopScope(
            canPop: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Text(AppLocaleKey.completeYourInformationToGetStarted.tr(), style: AppTextStyle.text18BS(context)),
                  const SizedBox(height: 20),
                  Text(
                    AppLocaleKey.completeYourInformationToGetStartedAndStartOrdering.tr(),
                    style: AppTextStyle.text16RS(context),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  CustomButton(
                    text: AppLocaleKey.startNow.tr(),
                    onPressed: () {
                      final authController = context.read<AuthController>();
                      if (authController.profile?.photoProfile == '') {
                        NavigatorMethods.pop(context);
                      }
                      NavigatorMethods.pushNamed(context, PersonalInformationDelegateScreen.routeName);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
