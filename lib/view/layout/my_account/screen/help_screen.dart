import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../controller/my_account_controller.dart';
import '../widget/help_box_widget.dart';

class HelpScreen extends StatefulWidget {
  static const String routeName = 'HelpScreen';
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF171A1F);
    const softText = Color(0xff7D8490);

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
      appBar: CustomAppBar(
        context,
        height: 86,
        title: Text(
          AppLocaleKey.help.tr(),
          style: const TextStyle(color: navy, fontSize: 21, fontWeight: FontWeight.w900),
        ),
      ),
      body: ChangeNotifierProvider(
        create: (_) => MyAccountController()
          ..initialHelp()
          ..getHelp(),
        child: Consumer<MyAccountController>(
          builder: (context, controller, _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(17),
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
                          child: const Icon(Icons.support_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocaleKey.help.tr(),
                                style: const TextStyle(color: navy, fontSize: 16, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.locale.languageCode == 'ar'
                                    ? 'إجابات سريعة لأكثر الأسئلة شيوعاً'
                                    : 'Quick answers to common questions',
                                style: const TextStyle(color: softText, fontSize: 12.5, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ApiResponseWidget(
                    apiResponse: controller.helpResponse,
                    onReload: controller.getHelp,
                    isEmpty: controller.help.isEmpty,
                    child: Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 30),
                        itemCount: controller.help.length,
                        itemBuilder: (context, index) {
                          return HelpBoxWidget(
                            question: controller.help[index].question ?? '',
                            answer: controller.help[index].answer ?? '',
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
