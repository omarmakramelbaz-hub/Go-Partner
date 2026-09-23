import 'dart:convert';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../../custom_widgets/custom_loading/custom_shimmer.dart';
import '../../auth/controller/auth_controller.dart';
import '../../wallet/screen/wallet_screen.dart';

class MyCurrentBalanceWidget extends StatefulWidget {
  const MyCurrentBalanceWidget({super.key});

  @override
  State<MyCurrentBalanceWidget> createState() => _MyCurrentBalanceWidgetState();
}

class _MyCurrentBalanceWidgetState extends State<MyCurrentBalanceWidget> {
  num? balance;
  num? minWallet;
  num? minWalletDisabled;
  late PusherController _pusherController;
  String? pusherWalletAmount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = context.read<AuthController>();
      authController.getProfile().then((_) {
        if (!mounted) return;
        setState(() {
          balance = authController.profile?.balance;
          minWallet = authController.profile?.minWallet;
          minWalletDisabled = authController.profile?.minWalletDisabled;
        });
      });
    });
    _pusherController = context.read<PusherController>();
    _pusherController.addEventListener('balance.updated', _handleWalletUpdate);
  }

  void _handleWalletUpdate(PusherEvent event) {
    try {
      final jsonData = jsonDecode(event.data) as Map<String, dynamic>;
      final amount = jsonData['user_balance']?.toString() ?? '0';
      pusherWalletAmount = num.parse(amount).toStringAsFixed(2);
      if (mounted) {
        context.read<AuthController>().getProfile().then((_) {
          if (!mounted) return;
          setState(() {
            balance = context.read<AuthController>().profile?.balance;
            minWallet = context.read<AuthController>().profile?.minWallet;
            minWalletDisabled = context.read<AuthController>().profile?.minWalletDisabled;
          });
        });
        setState(() {});
      }
    } catch (e, stackTrace) {
      log('Error handling wallet event: $e');
      log('$stackTrace');
    }
  }

  @override
  void dispose() {
    _pusherController.removeEventListener('balance.updated', _handleWalletUpdate);
    super.dispose();
  }

  String _t(String ar, String en) => context.locale.languageCode == 'ar' ? ar : en;

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xffFF7200);

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => NavigatorMethods.pushNamed(context, WalletScreen.routeName),
            borderRadius: BorderRadius.circular(27),
            child: Ink(
              width: double.infinity,
              height: 126,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(27),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xff151515), Color(0xff242424)],
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(.16), blurRadius: 24, offset: const Offset(0, 11)),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: -22,
                    top: -46,
                    child: Container(
                      width: 135,
                      height: 135,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: orange.withOpacity(.10)),
                    ),
                  ),
                  Positioned(
                    right: -35,
                    bottom: -60,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(.035)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            color: const Color(0xff2B2B2B),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.white.withOpacity(.08)),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.account_balance_wallet_outlined, color: orange, size: 38),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _t('محفظتي', 'My wallet'),
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                AppLocaleKey.myCurrentBalance.tr(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(.55),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              balance == null
                                  ? const CustomShimmer(height: 25, width: 100, radius: 8, shimmerColor: orange)
                                  : FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: AlignmentDirectional.centerStart,
                                      child: Text(
                                        AppLocaleKey.pound.tr().replaceAll(
                                          '{}',
                                          pusherWalletAmount ?? balance?.toStringAsFixed(0) ?? '0',
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 29,
                                          height: 1,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(color: orange, shape: BoxShape.circle),
                          child: Icon(
                            context.locale.languageCode == 'ar'
                                ? Icons.arrow_back_rounded
                                : Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (balance != null && minWallet != null && minWalletDisabled != null) ...[
          if (balance! >= minWalletDisabled! && balance! <= minWallet!) ...[
            const SizedBox(height: 8),
            _buildAlertContainer(context, AppLocaleKey.pleaseChargeYourBalance.tr(args: [minWallet!.toString()])),
          ],
          if (balance! < minWalletDisabled!) ...[
            const SizedBox(height: 8),
            _buildAlertContainer(
              context,
              AppLocaleKey.yourAccountIsCurrentlySuspended.tr(args: [minWallet!.toString()]),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildAlertContainer(BuildContext context, String message) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, WalletScreen.routeName),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColor.ffebbcColor(context),
            border: Border.all(color: const Color(0xffF6D98A)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.85),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const CustomImage(path: AppImages.infoIcon, type: ImageType.svg),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xff66511F),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
