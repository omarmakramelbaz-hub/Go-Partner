import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/images/app_images.dart';
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
      backgroundColor: const Color(0xffF8F9FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(0, 18, 0, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                'حسابي',
                style: TextStyle(color: navy, fontSize: 25, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xff171A1F), Color(0xff292D33)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: navy.withOpacity(.18),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -28,
                      top: -50,
                      child: Container(
                        width: 145,
                        height: 145,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(.05),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.14),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(19),
                            child: CustomImage(
                              path: hasPhoto ? profile?.photoProfile ?? '' : AppImages.userIcon,
                              type: hasPhoto ? ImageType.network : ImageType.svg,
                              height: 62,
                              width: 62,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile?.name ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    width: 29,
                                    height: 29,
                                    decoration: BoxDecoration(
                                      color: const Color(0xffFD7201).withOpacity(.20),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: const Icon(Icons.location_on_rounded, color: Color(0xffFF9A1A), size: 17),
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      profile?.areaTitle ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(.75),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.09),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(.10)),
                          ),
                          child: const Icon(Icons.verified_user_rounded, color: Color(0xffFF9A1A), size: 21),
                        ),
                      ],
                    ),
                  ],
                ),
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
            const SizedBox(height: 10),
            SettingButton(
              title: AppLocaleKey.personalInformation.tr(),
              onTap: () => NavigatorMethods.pushNamed(context, PersonalInformationDelegateScreen.routeName),
            ),
            const SizedBox(height: 10),
            SettingButton(
              title: AppLocaleKey.changePhoneNumber.tr(),
              onTap: () => NavigatorMethods.showAppBottomSheet(
                enableDrag: true,
                isScrollControlled: true,
                context,
                const ChangePhoneNumberBottomSheet(),
              ),
            ),
            const SizedBox(height: 10),
            SettingButton(
              title: AppLocaleKey.changePassword.tr(),
              onTap: () => NavigatorMethods.pushNamed(context, ChangePasswordDelegateScreen.routeName),
            ),
            const SizedBox(height: 10),
            SettingButton(
              title: AppLocaleKey.wallet.tr(),
              onTap: () => NavigatorMethods.pushNamed(context, WalletScreen.routeName),
            ),
            const SizedBox(height: 10),
            SettingButton(
              title: AppLocaleKey.changeLanguage.tr(),
              onTap: () => NavigatorMethods.showAppBottomSheet(context, const ChangeLangBottomSheet()),
            ),
            const SizedBox(height: 10),
            SettingButton(
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
            const SizedBox(height: 10),
            SettingButton(
              title: AppLocaleKey.termsAndConditions.tr(),
              onTap: () => NavigatorMethods.pushNamed(context, TermsAndConditionsScreen.routeName),
            ),
            const SizedBox(height: 10),
            SettingButton(
              title: AppLocaleKey.privacyPolicy.tr(),
              onTap: () => NavigatorMethods.pushNamed(context, PrivacyPolicyScreen.routeName),
            ),
            const SizedBox(height: 10),
            SettingButton(
              title: AppLocaleKey.connectWithUs.tr(),
              onTap: () => NavigatorMethods.pushNamed(context, ContactUsScreen.routeName),
            ),
            const SizedBox(height: 10),
            ChangeNotifierProvider(
              create: (_) => MyAccountController()
                ..initialSetting()
                ..getSetting(),
              child: Consumer<MyAccountController>(
                builder: (context, controller, _) {
                  return SettingButton(
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
            const SizedBox(height: 10),
            SettingButton(title: AppLocaleKey.deleteAccount.tr(), onTap: _confirmDeleteAccount),
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
                    decoration: BoxDecoration(
                      color: const Color(0xffFDEBEC),
                      borderRadius: BorderRadius.circular(17),
                    ),
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
