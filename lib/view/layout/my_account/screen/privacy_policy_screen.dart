import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../controller/my_account_controller.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  static const String routeName = 'PrivacyPolicyScreen';
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF171A1F);
    const softText = Color(0xff7D8490);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        context,
        height: 86,
        title: Text(
          AppLocaleKey.privacyPolicy.tr(),
          style: const TextStyle(color: navy, fontSize: 21, fontWeight: FontWeight.w900),
        ),
      ),
      body: ChangeNotifierProvider(
        create: (_) => MyAccountController()
          ..initialSetting()
          ..getSetting(),
        child: Consumer<MyAccountController>(
          builder: (context, controller, _) {
            return ApiResponseWidget(
              apiResponse: controller.settingResponse,
              onReload: controller.getSetting,
              isEmpty: controller.setting == null,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xffFFF7F0),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xffFFE0C5)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xffFF8A08), Color(0xffFF6500)]),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(Icons.privacy_tip_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocaleKey.privacyPolicy.tr(),
                                  style: const TextStyle(color: navy, fontSize: 16, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.locale.languageCode == 'ar'
                                      ? 'تعرف على كيفية حماية واستخدام بياناتك'
                                      : 'Learn how your data is protected and used',
                                  style: const TextStyle(color: softText, fontSize: 12.5, height: 1.4, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: const Color(0xffECEEF1)),
                        boxShadow: [
                          BoxShadow(
                            color: navy.withOpacity(.055),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: HtmlWidget(
                        controller.setting?.privacy ?? '',
                        textStyle: const TextStyle(
                          color: Color(0xff414854),
                          fontSize: 14,
                          height: 1.75,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
