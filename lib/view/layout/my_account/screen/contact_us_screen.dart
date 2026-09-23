import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../../../custom_widgets/validation/validation_mixin.dart';
import '../controller/my_account_controller.dart';
import '../widget/mobile_and_email_contact_us_widget.dart';

class ContactUsScreen extends StatefulWidget {
  static const String routeName = 'ContactUsScreen';
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> with ValidationMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameEc = TextEditingController();
  final _emailEc = TextEditingController();
  final _messages = TextEditingController();

  @override
  void dispose() {
    _nameEc.dispose();
    _emailEc.dispose();
    _messages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff171A1F);
    const softText = Color(0xff7D8490);

    return ChangeNotifierProvider(
      create: (_) => MyAccountController()
        ..initialSetting()
        ..getSetting(),
      child: Consumer<MyAccountController>(
        builder: (context, controller, _) {
          return Form(
            key: _formKey,
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: CustomAppBar(
                context,
                height: 86,
                title: Text(
                  AppLocaleKey.connectWithUs.tr(),
                  style: const TextStyle(color: navy, fontSize: 21, fontWeight: FontWeight.w900),
                ),
              ),
              body: ApiResponseWidget(
                apiResponse: controller.settingResponse,
                onReload: controller.getSetting,
                isEmpty: controller.setting == null,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
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
                            colors: [Color(0xff171A1F), Color(0xff292D33)],
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xffFF8A08), Color(0xffFF6500)]),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 25),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocaleKey.connectWithUs.tr(),
                                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    controller.setting?.contactText ?? '',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(.76),
                                      fontSize: 12.5,
                                      height: 1.55,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(23),
                          border: Border.all(color: const Color(0xffECEEF1)),
                          boxShadow: [
                            BoxShadow(
                              color: navy.withOpacity(.055),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: MobileAndEmailContactUsWidget(
                          mobile: controller.setting?.mobile ?? '',
                          email: controller.setting?.email ?? '',
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        context.locale.languageCode == 'ar' ? 'أرسل لنا رسالة' : 'Send us a message',
                        style: const TextStyle(color: navy, fontSize: 19, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        context.locale.languageCode == 'ar'
                            ? 'اكتب بياناتك وسنقوم بالرد عليك في أقرب وقت'
                            : 'Leave your details and we will get back to you soon',
                        style: const TextStyle(color: softText, fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 14),
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
                              controller: _nameEc,
                              validator: validateEmptyField,
                              title: AppLocaleKey.name.tr(),
                              prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xffAEB3BA), size: 21),
                            ),
                            const SizedBox(height: 18),
                            CustomFormField(
                              controller: _emailEc,
                              validator: validateEmail,
                              keyboardType: TextInputType.emailAddress,
                              title: AppLocaleKey.email.tr(),
                              prefixIcon: const Icon(Icons.email_outlined, color: Color(0xffAEB3BA), size: 21),
                            ),
                            const SizedBox(height: 18),
                            CustomFormField(
                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 15),
                              controller: _messages,
                              validator: validateEmptyField,
                              maxLines: 5,
                              title: AppLocaleKey.theMessage.tr(),
                            ),
                            const SizedBox(height: 20),
                            CustomButton(
                              prefixIcon: const Icon(Icons.send_rounded, color: Colors.white, size: 21),
                              text: AppLocaleKey.send.tr(),
                              onPressed: () {
                                if (!_formKey.currentState!.validate()) return;
                                controller.storeContact(
                                  name: _nameEc.text,
                                  email: _emailEc.text,
                                  message: _messages.text,
                                  onSuccess: () => Navigator.pop(context),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
