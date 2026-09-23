import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/networking/notification_helper.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../model/delegate_order_model.dart';
import '../screen/order_details_delegate_screen.dart';
import 'order_header_widget.dart';

class SingleOnGoingDelegateWidget extends StatefulWidget {
  const SingleOnGoingDelegateWidget({super.key, this.items, this.order, this.onSuccess});
  final List<DelegateItems>? items;
  final DelegateOrdersModel? order;
  final VoidCallback? onSuccess;

  @override
  State<SingleOnGoingDelegateWidget> createState() => _SingleOnGoingDelegateWidgetState();
}

class _SingleOnGoingDelegateWidgetState extends State<SingleOnGoingDelegateWidget> {
  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF171A1F);
    const softText = Color(0xff7D8490);
    const orange = Color(0xffFD7201);

    final isShipped = widget.order?.type == 'shipping';
    final fromAddress = isShipped
        ? (widget.order?.fromAddress ?? '')
        : (widget.order?.resturantLocation ?? '');
    final toAddress = isShipped
        ? (widget.order?.toAddress ?? '')
        : '${widget.order?.userAddress?.addressName ?? ''} ,${widget.order?.userAddress?.streetName ?? ''}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            SoundNotification.instance.stopSound();
            NavigatorMethods.pushNamed(
              context,
              OrderDetailsDelegateScreen.routeName,
              arguments: OrderDetailsDelegateScreenArgs(fromHome: false, orderId: widget.order?.id ?? 0),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xffECEEF1)),
              boxShadow: [
                BoxShadow(
                  color: navy.withOpacity(.06),
                  blurRadius: 21,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Column(
              children: [
                OrderHeaderWidget(order: widget.order, isShipped: isShipped),
                Container(height: 1, color: const Color(0xffF0F1F3)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 14, 15, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _AddressBlock(
                          icon: Icons.storefront_rounded,
                          title: AppLocaleKey.receivingAddress.tr(),
                          address: fromAddress,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Container(width: 1, height: 70, color: const Color(0xffECEEF1)),
                      ),
                      Expanded(
                        child: _AddressBlock(
                          icon: Icons.location_on_rounded,
                          title: AppLocaleKey.deliveryLocation.tr(),
                          address: toAddress,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: const Color(0xffF0F1F3)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xffFFF0E3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delivery_dining_rounded, color: orange, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppLocaleKey.deliveryCost.tr(),
                          style: const TextStyle(color: softText, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        AppLocaleKey.pound.tr().replaceAll('{}', '${widget.order?.deliveryPrice ?? 0} '),
                        style: const TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                if (widget.order?.paymentType == 'cash' && !isShipped)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xffF7F8FA),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Text(
                            AppLocaleKey.orderCost.tr(),
                            style: const TextStyle(color: softText, fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Text(
                            AppLocaleKey.pound.tr().replaceAll('{}', '${widget.order?.grandTotal ?? 0} '),
                            style: const TextStyle(color: navy, fontSize: 14.5, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressBlock extends StatelessWidget {
  const _AddressBlock({required this.icon, required this.title, required this.address});
  final IconData icon;
  final String title;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xffFFF0E3),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: const Color(0xffFD7201), size: 16),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF171A1F), fontSize: 12.5, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          address,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xff7D8490), fontSize: 12, height: 1.4, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
