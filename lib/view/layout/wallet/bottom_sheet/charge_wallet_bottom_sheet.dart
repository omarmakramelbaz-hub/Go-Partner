import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../custom_widgets/custom_payment_web_view/custom_payment_web_view.dart';
import '../../auth/controller/auth_controller.dart';
import '../../my_account/controller/my_account_controller.dart';
import '../controller/wallet_controller.dart';
import '../widget/chooseVCashOrVisaWidget.dart';
import '../widget/wallet_charge_view.dart';

class ChargeWalletBottomSheet extends StatefulWidget {
  const ChargeWalletBottomSheet({
    super.key,
    required this.walletController,
    required this.myAccountController,
  });
  final WalletController walletController;
  final MyAccountController myAccountController;

  @override
  State<ChargeWalletBottomSheet> createState() =>
      _ChargeWalletBottomSheetState();
}

class _ChargeWalletBottomSheetState extends State<ChargeWalletBottomSheet> {
  final chargeWalletFormKey = GlobalKey<FormState>();
  final chargeAmountEc = TextEditingController();
  final chargeAmountFocusNode = FocusNode();

  Future<void> _openPaymentPage(BuildContext context, String link) async {
    final uri = Uri.tryParse(link.trim());
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme.toLowerCase() != 'http' &&
            uri.scheme.toLowerCase() != 'https')) {
      CommonMethods.showError(
        message: 'تعذر فتح صفحة الدفع. رابط الدفع غير صالح.',
      );
      return;
    }

    log('Opening payment URL: $link');

    // webview_flutter has no web implementation in this project. On the web
    // preview open the gateway in the browser instead of trying to build a
    // mobile WebView route, which previously made the payment page appear to
    // do nothing.
    if (kIsWeb) {
      final opened = await launchUrl(uri, webOnlyWindowName: '_self');
      if (!opened) {
        CommonMethods.showError(message: 'تعذر فتح صفحة الدفع. حاول مرة أخرى.');
      }
      return;
    }

    if (!context.mounted) return;

    // Push the payment page directly on Android/iOS. This deliberately avoids
    // NavigatorMethods.currentRoute because that global value can stay stale
    // after the WebView pops itself and block a later payment attempt.
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => CustomPaymentWebViewScreen(
          args: PaymentArgs(
            url: link,
            onFailed: () {},
            onSuccess: () {
              if (context.mounted && Navigator.of(context).canPop()) {
                Navigator.pop(context);
              }
              widget.walletController.getWallet();
              widget.walletController.getRedirect();
              context.read<AuthController>().getProfile();
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    chargeAmountEc.dispose();
    chargeAmountFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WalletChargeSheetView(
    translate: (key) => key.tr(),
    formKey: chargeWalletFormKey,
    amountController: chargeAmountEc,
    amountFocusNode: chargeAmountFocusNode,
    validator: (value) {
      if (value == null || value.isEmpty) return 'enterAmount'.tr();
      final amount = num.tryParse(value);
      if (amount == null || amount < 50)
        return 'minimumChargeAmount'.tr().replaceAll('{}', '50');
      return null;
    },
    paymentMethods: ChooseVCashOrVisaWidget(
      myAccountController: widget.myAccountController,
    ),
    onPay: () {
      final valid = chargeWalletFormKey.currentState?.validate() ?? false;
      if (!valid) return;
      if (widget.walletController.selectedPayment == null) {
        CommonMethods.showError(
          message: AppLocaleKey.youMustChoosePaymentMethod.tr(),
        );
        return;
      }
      context.read<WalletController>().chargingWallet(
        amount: chargeAmountEc.text,
        onSuccess: (link) => _openPaymentPage(context, link),
      );
    },
  );
}
