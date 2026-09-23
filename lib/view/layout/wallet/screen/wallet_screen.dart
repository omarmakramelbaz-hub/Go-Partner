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
import '../../my_account/controller/my_account_controller.dart';
import '../bottom_sheet/charge_wallet_bottom_sheet.dart';
import '../bottom_sheet/mony_transfer_bottom_sheet.dart';
import '../controller/wallet_controller.dart';
import '../widget/my_current_balance_in_wallet_screen.dart';
import '../widget/recent_transactions_widget.dart';

class WalletScreen extends StatefulWidget {
  static const String routeName = 'WalletScreen';
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late PusherController _pusherController;
  String? pusherWalletAmount;

  @override
  void initState() {
    super.initState();
    _pusherController = context.read<PusherController>();
    _pusherController.addEventListener('balance.updated', _handleWalletUpdate);
  }

  void _handleWalletUpdate(PusherEvent event) {
    try {
      final jsonData = jsonDecode(event.data) as Map<String, dynamic>;
      log('Wallet updated: $jsonData');
      final amount = jsonData['user_balance']?.toString() ?? '0';
      pusherWalletAmount = num.parse(amount).toStringAsFixed(2);
      if (mounted) {
        setState(() => context.read<WalletController>().getWallet());
      }
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
    const navy = Color(0xff171A1F);
    const softText = Color(0xff7D8490);
    const orange = Color(0xffFD7201);

    return Consumer2<WalletController, MyAccountController>(
      builder: (context, walletController, myAccountController, _) {
        return Scaffold(
          backgroundColor: const Color(0xffF8F9FB),
          appBar: CustomAppBar(
            context,
            height: 86,
            appBarColor: const Color(0xff171A1F),
            title: Text(
              AppLocaleKey.wallet.tr(),
              style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MyCurrentBalanceInWalletScreenWidget(
                  wallet: walletController.wallet,
                  pusherWalletAmount: pusherWalletAmount,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(color: const Color(0xffECEEF1)),
                    boxShadow: [
                      BoxShadow(
                        color: navy.withOpacity(.055),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.locale.languageCode == 'ar' ? 'إجراءات المحفظة' : 'Wallet actions',
                        style: const TextStyle(color: navy, fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        context.locale.languageCode == 'ar'
                            ? 'حوّل الأموال أو اشحن رصيدك بسهولة'
                            : 'Transfer money or charge your balance easily',
                        style: const TextStyle(color: softText, fontSize: 12.5, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 15),
                      CustomButton(
                        color: Colors.white,
                        borderColor: const Color(0xffFFD2AD),
                        hasShadow: false,
                        prefixIcon: const Icon(Icons.swap_horiz_rounded, color: orange, size: 22),
                        style: const TextStyle(color: orange, fontSize: 16, fontWeight: FontWeight.w800),
                        text: AppLocaleKey.moneyTransfer.tr(),
                        onPressed: () {
                          NavigatorMethods.showAppBottomSheet(
                            enableDrag: true,
                            isScrollControlled: true,
                            context,
                            ChangeNotifierProvider.value(
                              value: walletController,
                              child: MoneyTransferBottomSheet(walletController: walletController),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xffFFF0E3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: orange, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppLocaleKey.recentTransactions.tr(),
                      style: const TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(23),
                    border: Border.all(color: const Color(0xffECEEF1)),
                  ),
                  child: ApiResponseWidget(
                    apiResponse: walletController.walletResponse,
                    onReload: walletController.getWallet,
                    isEmpty: walletController.wallet == null,
                    child: RecentTransactionsWidget(wallet: walletController.wallet),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: (myAccountController.setting?.walletCardActivate == 'false' &&
                    myAccountController.setting?.paymentCardActivate == 'false')
                ? const SizedBox.shrink()
                : CustomButton(
                    prefixIcon: const Icon(Icons.add_card_rounded, color: Colors.white, size: 22),
                    text: AppLocaleKey.walletCharging.tr(),
                    onPressed: () {
                      NavigatorMethods.showAppBottomSheet(
                        enableDrag: true,
                        isScrollControlled: true,
                        context,
                        ChangeNotifierProvider.value(
                          value: walletController,
                          child: ChargeWalletBottomSheet(
                            walletController: walletController,
                            myAccountController: myAccountController,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
