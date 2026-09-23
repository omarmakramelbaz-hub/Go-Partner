import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/utils/date_methods.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../auth/controller/auth_controller.dart';
import '../model/wallet_model.dart';

class RecentTransactionsWidget extends StatelessWidget {
  final WalletModel? wallet;

  const RecentTransactionsWidget({super.key, required this.wallet});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF171A1F);
    const softText = Color(0xff7D8490);
    const orange = Color(0xffFD7201);

    final transactions = wallet?.wallet ?? [];
    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xffFFF0E3),
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(Icons.receipt_long_outlined, color: orange, size: 25),
            ),
            const SizedBox(height: 10),
            Text(
              context.locale.languageCode == 'ar' ? 'لا توجد معاملات حتى الآن' : 'No transactions yet',
              style: const TextStyle(color: softText, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(transactions.length, (index) {
        final transaction = transactions[index];
        final isFromMe = context.read<AuthController>().profile?.id == transaction.fromUser;
        final isToMe = context.read<AuthController>().profile?.id == transaction.toUser;
        final isIncoming = isToMe || transaction.type == 'charging';

        final description =
            "${AppLocaleKey.theAmountIs.tr().replaceAll('{}', buildTransaction(transaction: transaction.type ?? ''))} "
            "${AppLocaleKey.pound.tr().replaceAll('{}', transaction.amount.toString())} "
            "${AppLocaleKey.paymentTypeIs.tr().replaceAll('{}', buildPaymentType(paymentType: transaction.payment ?? ''))} "
            "${transaction.fromUserName != null && transaction.toUserName != null ? AppLocaleKey.fromUser.tr().replaceAll('{}', isFromMe ? AppLocaleKey.yourWallet.tr() : transaction.fromUserName ?? '') : ''} "
            "${transaction.toUserName != null ? AppLocaleKey.toUser.tr().replaceAll('{}', isToMe ? AppLocaleKey.yourWallet.tr() : transaction.toUserName ?? '') : ''} "
            "${transaction.orderNo != null ? AppLocaleKey.orderNumber.tr().replaceAll('{}', transaction.orderNo ?? '') : ''}";

        return Container(
          margin: EdgeInsets.only(bottom: index == transactions.length - 1 ? 0 : 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xffFAFAFB),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xffECEEF1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isIncoming ? const Color(0xffEAF8F2) : const Color(0xffFFF0E3),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: transaction.payment == 'visa'
                    ? SvgPicture.asset(AppImages.visaIcon)
                    : transaction.payment == 'wallet'
                        ? CustomImage(
                            path: AppImages.paymentRDIcon,
                            type: ImageType.svg,
                            color: isIncoming ? const Color(0xff16A36A) : orange,
                          )
                        : Image.asset(AppImages.digitalWallet, height: 25),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            buildTransaction(transaction: transaction.type ?? ''),
                            style: const TextStyle(color: navy, fontSize: 14.5, fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          AppLocaleKey.pound.tr().replaceAll('{}', transaction.amount.toString()),
                          style: TextStyle(
                            color: isIncoming ? const Color(0xff16A36A) : orange,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description.trim(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: softText, fontSize: 11.5, height: 1.45, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, color: Color(0xff9AA0AA), size: 13),
                        const SizedBox(width: 4),
                        Text(
                          '${DateMethods.formatDateToArabic(transaction.createdAt ?? '')}  ${DateMethods.formatToTime(transaction.createdAt ?? '')}',
                          style: const TextStyle(color: Color(0xff9299A4), fontSize: 10.5, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String buildTransaction({required String transaction}) {
    switch (transaction) {
      case 'transfer':
        return AppLocaleKey.transfer.tr();
      case 'charging':
        return AppLocaleKey.charging.tr();
      case 'withdraw':
        return AppLocaleKey.withdraw.tr();
      case 'shipping':
        return AppLocaleKey.shipping.tr();
      default:
        return '';
    }
  }

  String buildPaymentType({required String paymentType}) {
    switch (paymentType) {
      case 'wallet':
        return AppLocaleKey.appWalletBalance.tr();
      case 'online':
      case 'visa':
        return AppLocaleKey.visa.tr();
      case 'v_cash':
        return AppLocaleKey.digitalWalletAndInstaPay.tr();
      default:
        return '';
    }
  }
}
