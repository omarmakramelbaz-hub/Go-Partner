import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/locale/app_locale_key.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../../custom_widgets/validation/validation_mixin.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/my_account_controller.dart';

class ChangePasswordDelegateScreen extends StatefulWidget {
  static const String routeName = 'ChangePasswordDelegateScreen';
  const ChangePasswordDelegateScreen({super.key});

  @override
  State<ChangePasswordDelegateScreen> createState() => _ChangePasswordDelegateScreenState();
}

class _ChangePasswordDelegateScreenState extends State<ChangePasswordDelegateScreen> with ValidationMixin {
  final _currentPasswordEc = TextEditingController();
  final _newPasswordEc = TextEditingController();
  final _confirmPasswordEc = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _currentPasswordEc.dispose();
    _newPasswordEc.dispose();
    _confirmPasswordEc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff171A1F);
    const softText = Color(0xff7D8490);
    final profile = context.watch<AuthController>().profile;
    final hasPhoto = profile?.photoProfile != null && profile!.photoProfile!.isNotEmpty;

    return ChangeNotifierProvider(
      create: (_) => MyAccountController(),
      child: Scaffold(
        backgroundColor: const Color(0xffF8F9FB),
        appBar: CustomAppBar(
          context,
          height: 86,
          title: Text(
            AppLocaleKey.changePassword.tr(),
            style: const TextStyle(color: navy, fontSize: 21, fontWeight: FontWeight.w900),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xffECEEF1)),
                    boxShadow: [
                      BoxShadow(
                        color: navy.withOpacity(.055),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xffFFF0E3),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: CustomImage(
                            path: hasPhoto ? profile?.photoProfile ?? '' : AppImages.userIcon,
                            type: hasPhoto ? ImageType.network : ImageType.svg,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile?.name ?? '',
                              style: const TextStyle(color: navy, fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              profile?.areaTitle ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: softText, fontSize: 12.5, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xffFFF0E3),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(Icons.lock_reset_rounded, color: Color(0xffFD7201), size: 22),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  context.locale.languageCode == 'ar' ? 'تحديث كلمة المرور' : 'Update password',
                  style: const TextStyle(color: navy, fontSize: 19, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  context.locale.languageCode == 'ar'
                      ? 'استخدم كلمة مرور قوية للحفاظ على أمان حسابك'
                      : 'Use a strong password to keep your account secure',
                  style: const TextStyle(color: softText, fontSize: 13, height: 1.45, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xffECEEF1)),
                  ),
                  child: Column(
                    children: [
                      CustomFormField(
                        controller: _currentPasswordEc,
                        title: AppLocaleKey.currentPassword.tr(),
                        isPassword: true,
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xffAEB3BA), size: 21),
                      ),
                      const SizedBox(height: 20),
                      CustomFormField(
                        validator: validateNewPassword,
                        controller: _newPasswordEc,
                        title: AppLocaleKey.newPassword.tr(),
                        isPassword: true,
                        prefixIcon: const Icon(Icons.password_rounded, color: Color(0xffAEB3BA), size: 21),
                      ),
                      const SizedBox(height: 20),
                      CustomFormField(
                        validator: validateConfirmPassword,
                        controller: _confirmPasswordEc,
                        title: AppLocaleKey.retypePassword.tr(),
                        isPassword: true,
                        prefixIcon: const Icon(Icons.verified_user_outlined, color: Color(0xffAEB3BA), size: 21),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Builder(
                  builder: (context) {
                    return CustomButton(
                      prefixIcon: const Icon(Icons.save_rounded, color: Colors.white, size: 21),
                      text: AppLocaleKey.saveChanges.tr(),
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        context.read<MyAccountController>().changePassword(
                          currentPassword: _currentPasswordEc.text,
                          newPassword: _newPasswordEc.text,
                          passwordConfirmation: _confirmPasswordEc.text,
                          onSuccess: () => Navigator.maybePop(context),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
