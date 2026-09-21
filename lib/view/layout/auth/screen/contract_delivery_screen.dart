import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/utils/date_methods.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../controller/delegate_controller.dart';

class ContractDeliveryArgs {
  final String? name;
  final String? nationalId;
  final String? drivingLicenseNo;
  final String? mobile;
  final String? email;
  final String? vodafoneCash;
  final VoidCallback onConfirm;

  ContractDeliveryArgs({
    required this.onConfirm,
    required this.name,
    required this.nationalId,
    required this.drivingLicenseNo,
    required this.mobile,
    required this.email,
    required this.vodafoneCash,
  });
}

class ContractDeliveryScreen extends StatelessWidget {
  final ContractDeliveryArgs args;
  static const String routeName = 'ContractDeliveryScreen';

  const ContractDeliveryScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xff171A1F);
    const softText = Color(0xff7D8490);

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
      appBar: CustomAppBar(
        context,
        height: 86,
        title: Text(
          AppLocaleKey.contract.tr(),
          style: const TextStyle(color: navy, fontSize: 21, fontWeight: FontWeight.w900),
        ),
      ),
      body: ChangeNotifierProvider(
        create: (_) => VendorAndDeliveryController()
          ..initialContract()
          ..getContract(typeContract: 'delegate'),
        child: Consumer<VendorAndDeliveryController>(
          builder: (context, controller, _) {
            String? template = controller.contract?.template;
            final data = <String, String>{
              '[contractDate]': DateMethods.formatToDate(DateTime.now().toString()),
              '[vendorName]': args.name ?? '',
              '[vendorNationalid]': args.nationalId ?? '',
              '[vendorDrivingLicenseNo]': args.drivingLicenseNo ?? '',
              '[vendorMobile]': args.mobile ?? '',
              '[vendorEmail]': args.email ?? '',
              '[vendorVodafoneCash]': args.vodafoneCash ?? '',
            };
            data.forEach((key, value) => template = template?.replaceAll(key, value));

            return ApiResponseWidget(
              apiResponse: controller.contractApiResponse,
              onReload: () => controller.getContract(typeContract: 'delegate'),
              isEmpty: controller.contract == null,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 115),
                child: Column(
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xffFF8A08), Color(0xffFF6500)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.description_rounded, color: Colors.white, size: 23),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocaleKey.contract.tr(),
                                  style: const TextStyle(color: navy, fontSize: 16, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.locale.languageCode == 'ar'
                                      ? 'يرجى قراءة بنود العقد بعناية قبل التأكيد'
                                      : 'Please read the contract carefully before confirming',
                                  style: const TextStyle(color: softText, fontSize: 12.5, height: 1.45, fontWeight: FontWeight.w500),
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
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: const Color(0xffECEEF1)),
                        boxShadow: [
                          BoxShadow(
                            color: navy.withOpacity(.065),
                            blurRadius: 22,
                            offset: const Offset(0, 9),
                          ),
                        ],
                      ),
                      child: HtmlWidget(
                        template ?? '',
                        textStyle: const TextStyle(
                          color: Color(0xff374151),
                          fontSize: 14,
                          height: 1.7,
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
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 8, 18, 12),
        child: CustomButton(
          prefixIcon: const Icon(Icons.task_alt_rounded, color: Colors.white, size: 22),
          text: AppLocaleKey.confirm.tr(),
          onPressed: args.onConfirm,
        ),
      ),
    );
  }
}
