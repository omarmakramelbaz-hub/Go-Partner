import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../my_account/controller/my_account_controller.dart';
import '../controller/wallet_controller.dart';

class ChooseVCashOrVisaWidget extends StatelessWidget {
  const ChooseVCashOrVisaWidget({super.key, required this.myAccountController});
  final MyAccountController myAccountController;

  @override
  Widget build(BuildContext context) {
    final methods = <Widget>[];

    if (myAccountController.setting?.walletCardActivate == 'true') {
      methods.add(PaymentMethodWidget(
        icon: AppImages.digitalWallet,
        label: 'محفظة إلكترونية',
        subtitle: 'Vodafone Cash والمحافظ الإلكترونية',
        selectedPayment: 'v_cash',
        isSvg: false,
      ));
    }
    if (myAccountController.setting?.paymentCardActivate == 'true') {
      methods.add(PaymentMethodWidget(
        icon: AppImages.visaIcon,
        label: AppLocaleKey.creditCard.tr(),
        subtitle: 'Visa / Mastercard',
        selectedPayment: 'online',
      ));
    }

    // Apple Pay and Google Pay are intentionally presented as separate choices.
    // Until Paymob provides/activates their dedicated integration IDs, both use
    // the existing online checkout route so no unverified gateway identifiers
    // are hard-coded in the app.
    if (myAccountController.setting?.paymentCardActivate == 'true') {
      methods.add(const PaymentMethodWidget(
        icon: '',
        label: 'Apple Pay',
        subtitle: 'الدفع السريع والآمن',
        selectedPayment: 'apple_pay',
        fallbackIcon: Icons.apple,
      ));
      methods.add(const PaymentMethodWidget(
        icon: '',
        label: 'Google Pay',
        subtitle: 'الدفع باستخدام Google Pay',
        selectedPayment: 'google_pay',
        fallbackIcon: Icons.account_balance_wallet_outlined,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('اختر طريقة الدفع', style: AppTextStyle.text16MS(context)),
        const SizedBox(height: 12),
        for (var i = 0; i < methods.length; i++) ...[
          methods[i],
          if (i != methods.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class PaymentMethodWidget extends StatelessWidget {
  final String icon;
  final String label;
  final String? subtitle;
  final bool isSvg;
  final String selectedPayment;
  final IconData? fallbackIcon;

  const PaymentMethodWidget({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.isSvg = true,
    required this.selectedPayment,
    this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final walletController = context.watch<WalletController>();
    final isSelected = walletController.selectedPayment == selectedPayment;
    final mainColor = AppColor.mainAppColor(context);

    Widget leading;
    if (fallbackIcon != null) {
      leading = Icon(fallbackIcon, size: 27, color: isSelected ? mainColor : AppColor.greyColor(context));
    } else {
      leading = isSvg
          ? SvgPicture.asset(icon, width: 27, height: 27)
          : Image.asset(icon, height: 27, width: 27, fit: BoxFit.contain);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => walletController.setSelectedPayment(selectedPayment),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected ? mainColor.withOpacity(.07) : AppColor.whiteColor(context),
            border: Border.all(
              color: isSelected ? mainColor : AppColor.borderColor(context),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color: isSelected ? mainColor.withOpacity(.12) : AppColor.greyColor(context).withOpacity(.08),
                ),
                alignment: Alignment.center,
                child: leading,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyle.text16MS(context)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: TextStyle(fontSize: 12, color: AppColor.greyColor(context)),
                      ),
                    ],
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 22,
                width: 22,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 1.5,
                    color: isSelected ? mainColor : AppColor.borderColor(context),
                  ),
                ),
                child: isSelected
                    ? DecoratedBox(
                        decoration: BoxDecoration(shape: BoxShape.circle, color: mainColor),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
