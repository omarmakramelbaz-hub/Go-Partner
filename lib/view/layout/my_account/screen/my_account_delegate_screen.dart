import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../../global/chat/screen/admin_chat_screen.dart';
import '../../auth/bottom_sheet/change_lang_bottom_sheet.dart';
import '../../auth/controller/auth_controller.dart';
import '../../auth/screen/login_screen.dart';
import '../../wallet/screen/wallet_screen.dart';
import '../controller/my_account_controller.dart';
import '../widget/change_phone_number.dart';
import '../widget/setting_button_widget.dart';
import 'change_password_delegate_screen.dart';
import 'contact_us_screen.dart';
import 'delegate_reports_screen.dart';
import 'personal_information_delgate_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_and_conditions_screen.dart';

class MyAccountDelegateScreen extends StatefulWidget {
  const MyAccountDelegateScreen({super.key});

  @override
  State<MyAccountDelegateScreen> createState() => _MyAccountDelegateScreenState();
}

class _MyAccountDelegateScreenState extends State<MyAccountDelegateScreen> {
  final codeEC = TextEditingController();

  @override
  void dispose() {
    codeEC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff171A1F);
    const softText = Color(0xff7D8490);
    final profile = context.watch<AuthController>().profile;
    final hasPhoto = profile?.photoProfile != null && profile!.photoProfile!.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xffFD7201), width: 2),
                    ),
                    child: ClipOval(
                      child: hasPhoto
                          ? CustomImage(path: profile!.photoProfile!, type: ImageType.network, fit: BoxFit.cover)
                          : const ColoredBox(
                              color: Color(0xffFFF1E5),
                              child: Icon(Icons.person_outline_rounded, size: 42, color: Color(0xffFD7201)),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile?.name ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: navy, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    profile?.mobile ?? '',
                    textDirection: ui.TextDirection.ltr,
                    style: const TextStyle(color: softText, fontSize: 13),
                  ),
                  if (profile?.areaTitle?.isNotEmpty == true) ...[
                    const SizedBox(height: 6),
                    Text(profile!.areaTitle!, style: const TextStyle(color: softText, fontSize: 12)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                context.locale.languageCode == 'ar' ? 'إعدادات الحساب' : 'Account settings',
                style: const TextStyle(color: softText, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            SettingButton(
              icon: Icons.person_outline_rounded,
              title: AppLocaleKey.personalInformation.tr(),
              onTap: () => NavigatorMethods.pushNamed(context, PersonalInformationDelegateScreen.routeName),
            ),
            SettingButton(
              icon: Icons.phone_outlined,
              title: AppLocaleKey.changePhoneNumber.tr(),
              onTap: () => NavigatorMethods.showAppBottomSheet(
                enableDrag: true,
                isScrollControlled: true,
                context,
                const ChangePhoneNumberBottomSheet(),
              ),
            ),
            SettingButton(
              icon: Icons.lock_outline_rounded,
              title: AppLocaleKey.changePassword.tr(),
              onTap: () => NavigatorMethods.pushNamed(context, ChangePasswordDelegateScreen.routeName),
            ),
            SettingButton(
              icon: Icons.account_balance_wallet_outlined,
              title: AppLocaleKey.wallet.tr(),
              onTap: () => NavigatorMethods.pushNamed(context, WalletScreen.routeName),
            ),
            SettingButton(
              icon: Icons.language_rounded,
              title: AppLocaleKey.changeLanguage.tr(),
              onTap: () => NavigatorMethods.showAppBottomSheet(context, const ChangeLangBottomSheet()),
            ),
            SettingButton(
              icon: Icons.bar_chart_rounded,
              title: AppLocaleKey.myReports.tr(),
              onTap: () => NavigatorMethods.pushNamed(context, DelegateReportsScreen.routeName),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                context.locale.languageCode == 'ar' ? 'المساعدة والقانونية' : 'Support & legal',
                style: const TextStyle(color: softText, fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            SettingButton(
              icon: Icons.description_outlined,
              title: AppLocaleKey.termsAndConditions.tr(),
              onTap: () => NavigatorMethods.pushNamed(context, TermsAndConditionsScreen.routeName),
            ),
            SettingButton(
              icon: Icons.shield_outlined,
              title: AppLocaleKey.privacyPolicy.tr(),
              onTap: () => NavigatorMethods.pushNamed(context, PrivacyPolicyScreen.routeName),
            ),
            SettingButton(
              icon: Icons.mail_outline_rounded,
              title: AppLocaleKey.connectWithUs.tr(),
              onTap: () => NavigatorMethods.pushNamed(context, ContactUsScreen.routeName),
            ),
            ChangeNotifierProvider(
              create: (_) => MyAccountController()
                ..initialSetting()
                ..getSetting(),
              child: Consumer<MyAccountController>(
                builder: (context, controller, _) {
                  return SettingButton(
                    icon: Icons.support_agent_rounded,
                    title: AppLocaleKey.connectSupport.tr(),
                    onTap: () {
                      NavigatorMethods.pushNamed(
                        context,
                        AdminChatScreen.routeName,
                        arguments: AdminChatScreenArgs(
                          senderId: context.read<AuthController>().profile!.id!.toString(),
                          receiverId: controller.setting?.adminId.toString() ?? '1',
                          receiverDeviceToken: controller.setting?.adminDeviceToken ?? '',
                          receiverName: 'admin',
                          senderName: context.read<AuthController>().profile?.name ?? '',
                          senderDeviceToken: '',
                          accountType: '',
                          isToVendor: false,
                          vendorDeviceToken: '',
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SettingButton(
              icon: Icons.delete_outline_rounded,
              destructive: true,
              title: AppLocaleKey.deleteAccount.tr(),
              onTap: _confirmDeleteAccount,
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: CustomButton(
                color: const Color(0xffE5484D),
                hasShadow: true,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xffE5484D).withOpacity(.20),
                    blurRadius: 17,
                    offset: const Offset(0, 7),
                  ),
                ],
                prefixIcon: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
                text: AppLocaleKey.logOut.tr(),
                onPressed: _confirmLogout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout() {
    CommonMethods.showChooseDialog(
      context,
      title: tr(AppLocaleKey.doYouWantToLogOut),
      message: '',
      onPressed: () {
        context.read<AuthController>().logout(
          onSuccess: () => NavigatorMethods.pushNamedAndRemoveUntil(context, LoginScreen.routeName),
        );
      },
    );
  }

  void _confirmDeleteAccount() {
    CommonMethods.showChooseDialog(
      context,
      onPressed: () {
        Navigator.pop(context);
        NavigatorMethods.showAppDialog(
          context,
          Dialog(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(color: const Color(0xffFDEBEC), borderRadius: BorderRadius.circular(17)),
                    child: const Icon(Icons.delete_outline_rounded, color: Color(0xffE5484D), size: 27),
                  ),
                  const SizedBox(height: 16),
                  CustomFormField(
                    title: AppLocaleKey.enterVerificationCode.tr(),
                    controller: codeEC,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    color: const Color(0xffE5484D),
                    text: AppLocaleKey.deleteAccount.tr(),
                    onPressed: () {
                      context.read<AuthController>().deleteAccount(
                        mobileCode: codeEC.text,
                        onSuccess: () => NavigatorMethods.pushNamedAndRemoveUntil(context, LoginScreen.routeName),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
      message: AppLocaleKey.didYouWantToDeleteThisAccount.tr(),
    );
  }
}
