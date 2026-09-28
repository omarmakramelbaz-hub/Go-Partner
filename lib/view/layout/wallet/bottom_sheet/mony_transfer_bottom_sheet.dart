import '../../../custom_widgets/popups/go_popups.dart';

import 'package:country_picker/country_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/country_code_methods.dart';
import '../../../custom_widgets/validation/validation_mixin.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/wallet_controller.dart';
import '../model/wallet_transfer.dart';
import '../widget/wallet_transfer_view.dart';

class MoneyTransferBottomSheet extends StatefulWidget {
  const MoneyTransferBottomSheet({super.key, required this.walletController});
  final WalletController walletController;

  @override
  State<MoneyTransferBottomSheet> createState() =>
      _MoneyTransferBottomSheetState();
}

class _MoneyTransferBottomSheetState extends State<MoneyTransferBottomSheet>
    with ValidationMixin {
  Country? _country;

  final chargeWalletFormKey = GlobalKey<FormState>();
  final chargeAmountEc = TextEditingController();
  final mobileEc = TextEditingController();
  final chargeAmountFocusNode = FocusNode();
  TransferWallet? _selectedWallet;
  WalletTransferPreview? _preview;
  bool _busy = false;

  @override
  void initState() {
    _country = CountryCodeMethods.getByCode('20');
    super.initState();
  }

  @override
  void dispose() {
    chargeAmountEc.dispose();
    mobileEc.dispose();
    chargeAmountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _reviewTransfer() async {
    if (_busy || !chargeWalletFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      _preview ??= await widget.walletController.checkMonyTransfer(
        wallet: _selectedWallet!,
        mobile: mobileEc.text.trim(),
        amount: num.parse(chargeAmountEc.text),
      );
      if (!mounted || _preview == null) return;
      final preview = _preview!;
      final confirmed = await showGoDialog<bool>(
        context: context,
        builder: (_) => WalletTransferReviewDialog(
          preview: preview,
          translate: (key) => key.tr(),
        ),
      );
      if (!mounted || confirmed != true) return;
      final result = await widget.walletController.chargingMonyTransfer(
        preview,
      );
      if (!mounted) return;
      if (result == true) {
        final auth = context.read<AuthController>();
        widget.walletController.getWallet();
        auth.getProfile();
        Navigator.pop(context);
      } else if (result == false) {
        _preview = null; // Explicit rejection: no money moved; request fresh confirmation.
      }
    } catch (_) {
      if (mounted)
        CommonMethods.showError(message: 'walletTransferFailed'.tr());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => WalletTransferSheetView(
    translate: (key) => key.tr(),
    formKey: chargeWalletFormKey,
    mobileController: mobileEc,
    amountController: chargeAmountEc,
    amountFocusNode: chargeAmountFocusNode,
    selectedWallet: _selectedWallet,
    busy: _busy,
    onWalletChanged: (wallet) => setState(() {
      _selectedWallet = wallet;
      _preview = null;
    }),
    onDetailsChanged: (_) => _preview = null,
    validatePhone: (value) => validatePhone(value, country: _country),
    validateAmount: (value) {
      if (value == null || value.isEmpty) return 'enterAmount'.tr();
      final amount = num.tryParse(value);
      if (amount == null ||
          amount < 1 ||
          amount > 5000 ||
          value.startsWith('0')) {
        return 'theMaximumTransferIs5000EGP'.tr();
      }
      return null;
    },
    onReview: _reviewTransfer,
    onClose: () => Navigator.pop(context),
  );
}
