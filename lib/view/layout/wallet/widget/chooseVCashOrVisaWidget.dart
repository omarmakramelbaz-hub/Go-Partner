import '../../../custom_widgets/popups/go_popups.dart';
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
    final ar = context.locale.languageCode == 'ar';
    final liveSettings = context.watch<MyAccountController>();
    final settings = liveSettings.setting ?? myAccountController.setting;

    if (settings?.walletCardActivate == 'true') {
      methods.add(PaymentMethodWidget(
        icon: AppImages.digitalWallet,
        label: ar ? 'محافظ إلكترونية' : 'Electronic wallets',
        subtitle: ar ? 'فودافون كاش وجميع المحافظ الإلكترونية' : 'Vodafone Cash and other electronic wallets',
        selectedPayment: 'v_cash',
        isSvg: false,
      ));
    }
    if (settings?.paymentCardActivate == 'true') {
      methods.add(PaymentMethodWidget(
        icon: AppImages.visaIcon,
        label: ar ? 'بطاقات بنكية' : 'Bank cards',
        subtitle: 'Visa / Mastercard',
        selectedPayment: 'online',
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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

    return GoPopupChoice(label: label, subtitle: subtitle, leading: leading,
      selected: isSelected, onTap: () => walletController.setSelectedPayment(selectedPayment));
  }
}
