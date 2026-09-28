import '../../../custom_widgets/popups/go_popups.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../helpers/theme/go_design_tokens.dart';
import '../model/wallet_transfer.dart';

/// Shared presentation in GO Customer and GO Partner. Destinations and the
/// authenticated confirmation flow remain owned by each app's controller.
class WalletTransferSheetView extends StatelessWidget {
  const WalletTransferSheetView({
    super.key,
    required this.translate,
    required this.formKey,
    required this.mobileController,
    required this.amountController,
    required this.amountFocusNode,
    required this.selectedWallet,
    required this.onWalletChanged,
    required this.onDetailsChanged,
    required this.validatePhone,
    required this.validateAmount,
    required this.onReview,
    required this.onClose,
    this.busy = false,
  });

  final String Function(String) translate;
  final GlobalKey<FormState> formKey;
  final TextEditingController mobileController, amountController;
  final FocusNode amountFocusNode;
  final TransferWallet? selectedWallet;
  final ValueChanged<TransferWallet> onWalletChanged;
  final ValueChanged<String> onDetailsChanged;
  final FormFieldValidator<String> validatePhone, validateAmount;
  final VoidCallback onReview, onClose;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final t = translate;
    return GoSheet(
      title: t('walletTransferTitle'),
      subtitle: t('walletTransferIntro'),
      icon: Icons.swap_horiz_rounded,
      includeKeyboardInset: true,
      busy: busy,
      onClose: onClose,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FieldLabel(t('recipientWallet')),
            const SizedBox(height: 10),
            FormField<TransferWallet>(
              validator: (_) =>
                  selectedWallet == null ? t('chooseRecipientWallet') : null,
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final wallet in TransferWallet.values) ...[
                    _WalletChoice(
                      wallet: wallet,
                      label: t(wallet.labelKey),
                      selected: selectedWallet == wallet,
                      onTap: busy
                          ? null
                          : () {
                              onWalletChanged(wallet);
                              field.didChange(wallet);
                              field.validate();
                            },
                    ),
                    if (wallet != TransferWallet.values.last)
                      const SizedBox(height: 8),
                  ],
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        field.errorText!,
                        style: const TextStyle(
                          color: GoDesign.danger,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _FieldLabel(t('walletTransferPhone')),
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextFormField(
                key: const ValueKey('wallet-transfer-phone'),
                controller: mobileController,
                enabled: !busy,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => amountFocusNode.requestFocus(),
                onChanged: onDetailsChanged,
                validator: validatePhone,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                style: const TextStyle(
                  color: GoDesign.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _decoration('01xxxxxxxxx').copyWith(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+20',
                          style: TextStyle(
                            color: GoDesign.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 12),
                        SizedBox(
                          height: 22,
                          child: VerticalDivider(
                            width: 1,
                            color: GoDesign.border,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _FieldLabel(t('walletTransferAmount')),
            const SizedBox(height: 8),
            TextFormField(
              key: const ValueKey('wallet-transfer-amount'),
              controller: amountController,
              focusNode: amountFocusNode,
              enabled: !busy,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              textDirection: TextDirection.ltr,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: onDetailsChanged,
              onFieldSubmitted: (_) => amountFocusNode.unfocus(),
              validator: validateAmount,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              style: const TextStyle(
                color: GoDesign.ink,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
              decoration: _decoration('0').copyWith(
                suffixIcon: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t('walletTransferCurrency'),
                        style: const TextStyle(
                          color: GoDesign.authMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t('walletTransferLimit'),
              style: const TextStyle(color: GoDesign.authMuted, fontSize: 12),
            ),
            const SizedBox(height: 24),
            GoPopupPrimaryButton(
              key: const ValueKey('wallet-transfer-review'),
              label: t('reviewWalletTransfer'),
              busy: busy,
              onPressed: busy ? null : onReview,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 15,
                  color: GoDesign.authMuted,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    t('walletTransferReviewHint'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: GoDesign.authMuted,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: Color(0xFF989FA9),
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
    filled: true,
    fillColor: GoDesign.canvas,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: GoDesign.fieldBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: GoDesign.fieldBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: GoDesign.orange, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: GoDesign.danger),
    ),
    errorMaxLines: 3,
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: GoDesign.ink,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _TransferIcon extends StatelessWidget {
  const _TransferIcon();
  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      gradient: GoDesign.actionGradient,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 28),
  );
}

class _WalletChoice extends StatelessWidget {
  const _WalletChoice({
    required this.wallet,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final TransferWallet wallet;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    checked: selected,
    inMutuallyExclusiveGroup: true,
    child: Material(
      color: selected ? GoDesign.orangeTint : GoDesign.canvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? GoDesign.orange : GoDesign.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('wallet-choice-${wallet.value}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(
                wallet.value == 'go_partner'
                    ? Icons.business_center_outlined
                    : Icons.account_balance_wallet_outlined,
                size: 23,
                color: selected ? GoDesign.orange : GoDesign.authMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: GoDesign.ink,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                size: 21,
                color: selected ? GoDesign.orange : const Color(0xFFBEC4CC),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class WalletTransferReviewDialog extends StatelessWidget {
  const WalletTransferReviewDialog({
    super.key,
    required this.preview,
    required this.translate,
  });
  final WalletTransferPreview preview;
  final String Function(String) translate;
  @override
  Widget build(BuildContext context) {
    final t = translate;
    return Dialog(
      backgroundColor: GoDesign.paper,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GoDesign.dialogRadius),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: _TransferIcon()),
              const SizedBox(height: 16),
              Text(
                t('reviewWalletTransfer'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: GoDesign.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t('walletTransferReviewHint'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: GoDesign.authMuted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: GoDesign.orangeTint,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Text(
                      t('walletTransferAmount'),
                      style: const TextStyle(
                        color: GoDesign.authMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${preview.amount.toStringAsFixed(2)} ${t('walletTransferCurrency')}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: GoDesign.ink,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _reviewDetail(t('recipientWallet'), t(preview.wallet.labelKey)),
              _reviewDetail(t('walletRecipientName'), preview.recipientName),
              _reviewDetail(
                t('walletTransferPhone'),
                preview.mobile,
                ltr: true,
              ),
              const SizedBox(height: 8),
              GoPopupPrimaryButton(
                key: const ValueKey('wallet-transfer-confirm'),
                label: t('walletTransferConfirm'),
                onPressed: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const ValueKey('wallet-transfer-edit'),
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  foregroundColor: GoDesign.authMuted,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(t('walletTransferEdit')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reviewDetail(String label, String value, {bool ltr = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              label,
              style: const TextStyle(color: GoDesign.authMuted, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textDirection: ltr ? TextDirection.ltr : null,
              style: const TextStyle(
                color: GoDesign.ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}
