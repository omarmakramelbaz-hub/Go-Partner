import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../custom_widgets/custom_loading/custom_shimmer.dart';
import '../model/wallet_model.dart';

class MyCurrentBalanceInWalletScreenWidget extends StatelessWidget {
  final WalletModel? wallet;
  final String? pusherWalletAmount;

  const MyCurrentBalanceInWalletScreenWidget({super.key, required this.wallet, this.pusherWalletAmount});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF171A1F);

    return Container(
      width: double.infinity,
      height: 154,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF171A1F), Color(0xff292D33)],
        ),
        boxShadow: [BoxShadow(color: navy.withOpacity(.22), blurRadius: 28, offset: const Offset(0, 13))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -38,
            top: -48,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(.05)),
            ),
          ),
          Positioned(
            right: 38,
            bottom: -70,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xffFD7201).withOpacity(.16)),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocaleKey.myCurrentBalance.tr(),
                      style: TextStyle(color: Colors.white.withOpacity(.72), fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 13),
                    wallet?.balance == null
                        ? const CustomShimmer(height: 28, width: 125, radius: 7, shimmerColor: Color(0xffFF8A08))
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              AppLocaleKey.pound.tr().replaceAll(
                                '{}',
                                pusherWalletAmount ?? wallet?.balance?.toStringAsFixed(2) ?? '0',
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                height: 1.1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.09),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        context.locale.languageCode == 'ar' ? 'رصيد متاح للاستخدام' : 'Available balance',
                        style: TextStyle(
                          color: Colors.white.withOpacity(.76),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xffFF9A1A), Color(0xffFF6500)],
                  ),
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xffFD7201).withOpacity(.32),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 32),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
