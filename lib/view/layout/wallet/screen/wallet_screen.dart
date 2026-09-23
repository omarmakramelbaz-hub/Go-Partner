import 'dart:convert';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../global/partner/partner_identity.dart';
import '../../my_account/controller/my_account_controller.dart';
import '../bottom_sheet/charge_wallet_bottom_sheet.dart';
import '../bottom_sheet/mony_transfer_bottom_sheet.dart';
import '../controller/wallet_controller.dart';
import '../widget/my_current_balance_in_wallet_screen.dart';
import '../widget/recent_transactions_widget.dart';

/// Owns its dependencies for both the bottom tab and a pushed route.
class WalletScreen extends StatelessWidget {
  static const String routeName = 'WalletScreen';
  const WalletScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => WalletController()..getWallet()),
      ChangeNotifierProvider(create: (_) => MyAccountController()..getSetting()),
    ],
    child: WalletContent(embedded: embedded),
  );
}

class WalletContent extends StatefulWidget {
  const WalletContent({super.key, this.embedded = false});
  final bool embedded;

  @override
  State<WalletContent> createState() => _WalletContentState();
}

class _WalletContentState extends State<WalletContent> {
  late PusherController _pusherController;

  @override
  void initState() {
    super.initState();
    _pusherController = context.read<PusherController>();
    _pusherController.addEventListener('balance.updated', _handleWalletUpdate);
  }

  void _handleWalletUpdate(PusherEvent event) {
    try {
      jsonDecode(event.data);
      if (!mounted) return;
      context.read<WalletController>().getWallet();
    } catch (e, stackTrace) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    _pusherController.removeEventListener('balance.updated', _handleWalletUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ar = context.locale.languageCode == 'ar';
    return Consumer2<WalletController, MyAccountController>(
      builder: (context, walletController, settingsController, _) {
        final settings = settingsController.setting;
        final canCharge =
            settings != null && (settings.walletCardActivate == 'true' || settings.paymentCardActivate == 'true');
        final body = RefreshIndicator(
          onRefresh: walletController.getWallet,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
            children: [
              ApiResponseWidget(
                apiResponse: walletController.walletResponse,
                onReload: walletController.getWallet,
                isEmpty: walletController.wallet == null,
                loadingWidget: MyCurrentBalanceInWalletScreenWidget(wallet: walletController.wallet),
                child: MyCurrentBalanceInWalletScreenWidget(wallet: walletController.wallet),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  if (canCharge) ...[
                    Expanded(
                      child: CustomButton(
                        height: 48,
                        hasShadow: false,
                        prefixIcon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        text: ar ? 'شحن الرصيد' : 'Top up',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                        onPressed: () => NavigatorMethods.showAppBottomSheet(
                          context,
                          enableDrag: true,
                          isScrollControlled: true,
                          ChangeNotifierProvider.value(
                            value: walletController,
                            child: ChargeWalletBottomSheet(
                              walletController: walletController,
                              myAccountController: settingsController,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: CustomButton(
                      height: 48,
                      color: Colors.white,
                      borderColor: PartnerIdentity.border,
                      hasShadow: false,
                      prefixIcon: const Icon(Icons.swap_horiz_rounded, color: PartnerIdentity.ink, size: 20),
                      style: const TextStyle(color: PartnerIdentity.ink, fontSize: 14, fontWeight: FontWeight.w700),
                      text: AppLocaleKey.moneyTransfer.tr(),
                      onPressed: () => NavigatorMethods.showAppBottomSheet(
                        context,
                        enableDrag: true,
                        isScrollControlled: true,
                        ChangeNotifierProvider.value(
                          value: walletController,
                          child: MoneyTransferBottomSheet(walletController: walletController),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocaleKey.recentTransactions.tr(),
                      style: const TextStyle(color: PartnerIdentity.ink, fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: ar ? 'تحديث المعاملات' : 'Refresh transactions',
                    onPressed: walletController.getWallet,
                    icon: const Icon(Icons.refresh_rounded, size: 21, color: PartnerIdentity.muted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ApiResponseWidget(
                apiResponse: walletController.walletResponse,
                onReload: walletController.getWallet,
                isEmpty: false,
                child: RecentTransactionsWidget(wallet: walletController.wallet),
              ),
            ],
          ),
        );
        if (widget.embedded) return body;
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: CustomAppBar(context, title: Text(AppLocaleKey.wallet.tr())),
          body: body,
        );
      },
    );
  }
}
