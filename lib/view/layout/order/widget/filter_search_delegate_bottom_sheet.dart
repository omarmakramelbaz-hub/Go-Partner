import '../../../custom_widgets/popups/go_popups.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/utils/date_methods.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_form_field/custom_form_field.dart';
import '../controller/delegate_order_controller.dart';

class FilterSearchDelegateBottomSheet extends StatefulWidget {
  const FilterSearchDelegateBottomSheet({super.key});

  @override
  State<FilterSearchDelegateBottomSheet> createState() => _FilterSearchDelegateBottomSheetState();
}

class _FilterSearchDelegateBottomSheetState extends State<FilterSearchDelegateBottomSheet> {
  int? indexDelivery;
  int? indexOrderStatus;
  final dateEc = TextEditingController();
  @override
  void dispose() { dateEc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GoSheet(title: AppLocaleKey.theFilter.tr(), icon: Icons.filter_list_rounded,
    includeKeyboardInset: true,
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(AppLocaleKey.orderStatus.tr(), style: AppTextStyle.text16MS(context)),
            const SizedBox(height: 17),
            Row(
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      indexOrderStatus = 0;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: indexOrderStatus == 0 ? AppColor.mainAppColor(context) : AppColor.whiteColor(context),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColor.borderColor(context)),
                    ),
                    child: Center(
                      child: Text(
                        AppLocaleKey.inPreparation.tr(),
                        style: indexOrderStatus == 0 ? AppTextStyle.text14MW(context) : AppTextStyle.text14MS(context),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 29),
                InkWell(
                  onTap: () {
                    setState(() {
                      indexOrderStatus = 1;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: indexOrderStatus == 1 ? AppColor.mainAppColor(context) : AppColor.whiteColor(context),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColor.borderColor(context)),
                    ),
                    child: Center(
                      child: Text(
                        AppLocaleKey.shipped.tr(),
                        style: indexOrderStatus == 1 ? AppTextStyle.text14MW(context) : AppTextStyle.text14MS(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 27),
            Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: CustomFormField(
                controller: dateEc,
                readOnly: true,
                onTap: () {
                  DateMethods.pickDate(
                    context,
                    initialDate: DateTime.now(),
                    onSuccess: (date) {
                      dateEc.text = DateMethods.formatToDate(date.toString());
                    },
                  );
                },
                title: AppLocaleKey.date.tr(),
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: AppLocaleKey.filter.tr(),
              onPressed: () {
                context.read<DelegateOrdersController>().ongoingOrderPage = 1;
                context.read<DelegateOrdersController>().getDelegateOngoingOrders(
                  date: dateEc.text,
                  type: indexOrderStatus == 0
                      ? 'accepted'
                      : indexOrderStatus == 1
                      ? 'shipped '
                      : null,
                  delegateFromOut: indexDelivery == 0
                      ? 'in_resturant'
                      : indexDelivery == 1
                      ? 'out_resturant'
                      : null,
                );
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),

    ]));
}
