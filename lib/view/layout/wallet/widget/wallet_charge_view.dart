import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../custom_widgets/popups/go_popups.dart';
import '../../../../helpers/theme/go_design_tokens.dart';

class WalletChargeSheetView extends StatelessWidget {
  const WalletChargeSheetView({
    super.key,
    required this.translate,
    required this.formKey,
    required this.amountController,
    required this.amountFocusNode,
    required this.validator,
    required this.paymentMethods,
    required this.onPay,
  });
  final String Function(String) translate;
  final GlobalKey<FormState> formKey;
  final TextEditingController amountController;
  final FocusNode amountFocusNode;
  final FormFieldValidator<String> validator;
  final Widget paymentMethods;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) => GoSheet(
    title: translate('walletCharging'),
    subtitle: translate('walletChargeIntro'),
    icon: Icons.add_card_rounded,
    includeKeyboardInset: true,
    child: Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            translate('chargeAmount'),
            style: const TextStyle(
              color: GoDesign.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: const ValueKey('wallet-charge-amount'),
            controller: amountController,
            focusNode: amountFocusNode,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            textDirection: TextDirection.ltr,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onFieldSubmitted: (_) => amountFocusNode.unfocus(),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: const TextStyle(
              color: GoDesign.ink,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              hintText: '0',
              suffixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      translate('walletTransferCurrency'),
                      style: const TextStyle(
                        color: GoDesign.authMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            translate('walletChargeMinimum'),
            style: const TextStyle(color: GoDesign.authMuted, fontSize: 12),
          ),
          const SizedBox(height: 24),
          Text(
            translate('walletChargeMethod'),
            style: const TextStyle(
              color: GoDesign.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          paymentMethods,
          const SizedBox(height: 24),
          GoPopupPrimaryButton(
            key: const ValueKey('wallet-charge-pay'),
            label: translate('payNow'),
            icon: Icons.lock_outline_rounded,
            onPressed: onPay,
          ),
        ],
      ),
    ),
  );
}
