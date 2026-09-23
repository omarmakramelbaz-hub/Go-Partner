import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/locale/app_locale_key.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../../global/widget/custom_image_container.dart';
import '../../auth/controller/auth_controller.dart';
import '../../auth/controller/auth_delegate_controller.dart';

class PersonalInformationDelegateScreen extends StatefulWidget {
  static const String routeName = 'PersonalInformationDelegateScreen';
  const PersonalInformationDelegateScreen({super.key});

  @override
  State<PersonalInformationDelegateScreen> createState() => _PersonalInformationDelegateScreenState();
}

class _PersonalInformationDelegateScreenState extends State<PersonalInformationDelegateScreen> {
  final _nameEc = TextEditingController();
  final _mobileEc = TextEditingController();
  final _emailEc = TextEditingController();
  final delegateFees = TextEditingController();
  File? _delegateImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      auth.initialProfile();
      auth.getProfile().then((_) {
        if (!mounted) return;
        _nameEc.text = auth.profile?.name ?? '';
        _emailEc.text = auth.profile?.email ?? '';
        _mobileEc.text = auth.profile?.mobile ?? '';
        delegateFees.text = '${auth.profile?.delegateFees?.toString() ?? ''} %';
      });
    });
  }

  @override
  void dispose() {
    _nameEc.dispose();
    _emailEc.dispose();
    _mobileEc.dispose();
    delegateFees.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF171A1F);
    const softText = Color(0xff7D8490);

    return Consumer<AuthController>(
      builder: (context, authController, _) {
        final profile = authController.profile;
        final hasPhoto = profile?.photoProfile != null && profile!.photoProfile!.isNotEmpty;

        return Scaffold(
          backgroundColor: const Color(0xffF8F9FB),
          appBar: CustomAppBar(
            context,
            height: 86,
            title: Text(
              AppLocaleKey.personalInformation.tr(),
              style: const TextStyle(color: navy, fontSize: 21, fontWeight: FontWeight.w900),
            ),
          ),
          body: ApiResponseWidget(
            apiResponse: authController.profileResponse,
            onReload: authController.getProfile,
            isEmpty: authController.profile == null,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 115),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF171A1F), Color(0xFF292D33)],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: navy.withOpacity(.18),
                          blurRadius: 24,
                          offset: const Offset(0, 11),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(21),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: CustomImage(
                              path: hasPhoto ? profile?.photoProfile ?? '' : AppImages.userIcon,
                              type: hasPhoto ? ImageType.network : ImageType.svg,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile?.name ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const CustomImage(path: AppImages.egyptIcon, type: ImageType.svg, height: 20, width: 20),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      profile?.areaTitle ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(.75),
                                        fontSize: 12.5,
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
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.09),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(Icons.badge_outlined, color: Color(0xffFF9A1A), size: 22),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    context.locale.languageCode == 'ar' ? 'بيانات الحساب' : 'Account details',
                    style: const TextStyle(color: navy, fontSize: 19, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    context.locale.languageCode == 'ar'
                        ? 'يمكنك تحديث بياناتك الأساسية وصورتك الشخصية'
                        : 'Update your basic details and profile photo',
                    style: const TextStyle(color: softText, fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xffECEEF1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomFormField(
                          controller: _nameEc,
                          title: AppLocaleKey.name.tr(),
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xffAEB3BA), size: 21),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppLocaleKey.logoImage.tr(),
                          style: const TextStyle(color: navy, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xffFAFAFB),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xffECEEF1)),
                          ),
                          child: CustomImageContainer(
                            bgImage: profile?.photoProfile,
                            image: _delegateImage,
                            onSuccess: (v) => setState(() => _delegateImage = v),
                          ),
                        ),
                        const SizedBox(height: 20),
                        CustomFormField(
                          controller: _mobileEc,
                          title: AppLocaleKey.phone.tr(),
                          readOnly: true,
                          prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xffAEB3BA), size: 21),
                        ),
                        const SizedBox(height: 20),
                        CustomFormField(
                          controller: _emailEc,
                          title: AppLocaleKey.email.tr(),
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xffAEB3BA), size: 21),
                        ),
                        const SizedBox(height: 20),
                        CustomFormField(
                          readOnly: true,
                          controller: delegateFees,
                          title: AppLocaleKey.delegateSubscriptionFee.tr(),
                          prefixIcon: const Icon(Icons.percent_rounded, color: Color(0xffAEB3BA), size: 21),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: CustomButton(
              prefixIcon: const Icon(Icons.save_rounded, color: Colors.white, size: 21),
              text: AppLocaleKey.saveChanges.tr(),
              onPressed: () {
                context.read<AuthDelegateController>().updateDelegateInfo(
                  name: _nameEc.text,
                  email: _emailEc.text,
                  photoProfile: _delegateImage,
                  onSuccess: () {
                    Navigator.pop(context);
                    authController.getProfile();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}
