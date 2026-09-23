import 'dart:convert';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../helpers/images/app_images.dart';
import '../../../helpers/locale/app_locale_key.dart';
import '../../../helpers/networking/notification_helper.dart';
import '../../../helpers/pusher_service/pusher_controller.dart';
import '../../../helpers/utils/date_methods.dart';
import '../../../helpers/utils/navigator_methods.dart';
import '../../custom_widgets/custom_image/custom_image.dart';
import '../../layout/order/model/delegate_order_model.dart';
import '../../layout/order/screen/order_details_delegate_screen.dart';

class OrderDelegateWidget extends StatefulWidget {
  const OrderDelegateWidget({
    super.key,
    this.isDelivered,
    this.orderItem,
    this.order,
    required this.orderId,
    this.onsuccess,
  });

  final bool? isDelivered;
  final List<DelegateItems>? orderItem;
  final DelegateOrdersModel? order;
  final int orderId;
  final VoidCallback? onsuccess;

  @override
  State<OrderDelegateWidget> createState() => _OrderDelegateWidgetState();
}

class _OrderDelegateWidgetState extends State<OrderDelegateWidget> {
  String status = 'pending';
  late PusherController _pusherController;

  @override
  void initState() {
    super.initState();
    status = widget.order?.status ?? 'pending';
    _pusherController = context.read<PusherController>();
    _pusherController.addEventListener('delegate.updated', _handleDelegateUpdated);
  }

  void _handleDelegateUpdated(PusherEvent event) {
    try {
      final jsonData = jsonDecode(event.data) as Map<String, dynamic>;
      if (!mounted) return;
      final order = jsonData['order'];
      if (order is Map<String, dynamic>) {
        setState(() => status = order['status']?.toString() ?? status);
      }
    } catch (e, stackTrace) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $stackTrace');
    }
  }

  @override
  void dispose() {
    _pusherController.removeEventListener('delegate.updated', _handleDelegateUpdated);
    super.dispose();
  }

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
              arguments: OrderDetailsDelegateScreenArgs(fromHome: true, orderId: widget.orderId),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xffECEEF1)),
              boxShadow: [
                BoxShadow(
                  color: navy.withOpacity(.065),
                  blurRadius: 22,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xffFFF4EB),
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(color: const Color(0xffFFE2C9)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CustomImage(
                            path: widget.order?.userLogo == null || widget.order?.userLogo == ''
                                ? AppImages.userIcon
                                : widget.order?.userLogo ?? '',
                            type: widget.order?.userLogo == null || widget.order?.userLogo == ''
                                ? ImageType.svg
                                : ImageType.network,
                            height: 52,
                            width: 52,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.order?.userName ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: navy, fontSize: 16.5, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppLocaleKey.orderNumber.tr().replaceAll('{}', widget.order?.orderNo ?? ''),
                              style: const TextStyle(color: softText, fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                const Icon(Icons.schedule_rounded, size: 15, color: Color(0xff9AA0AA)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${DateMethods.formatToDate(widget.order?.createdAt?.toString() ?? '')}  ${DateMethods.formatToTime(widget.order?.createdAt?.toString() ?? '')}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xff8B929D),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xffFFF0E3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isShipped ? AppLocaleKey.shippingOrder.tr() : AppLocaleKey.restaurantOrder.tr(),
                          style: const TextStyle(color: orange, fontSize: 11.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(height: 1, color: const Color(0xffF0F1F3)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 14, 15, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _LocationBlock(
                          title: AppLocaleKey.receivingAddress.tr(),
                          address: fromAddress,
                          icon: Icons.storefront_rounded,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Container(width: 1, height: 70, color: const Color(0xffECEEF1)),
                      ),
                      Expanded(
                        child: _LocationBlock(
                          title: AppLocaleKey.deliveryLocation.tr(),
                          address: toAddress,
                          icon: Icons.location_on_rounded,
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
                        AppLocaleKey.pound.tr().replaceAll(
                          '{}',
                          '${widget.order?.deliveryPrice?.toStringAsFixed(0) ?? '0'} ',
                        ),
                        style: const TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                if (widget.order?.paymentType == 'cash' && !isShipped) ...[
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
                            AppLocaleKey.pound.tr().replaceAll(
                              '{}',
                              '${widget.order?.grandTotal?.toStringAsFixed(0) ?? '0'} ',
                            ),
                            style: const TextStyle(color: navy, fontSize: 14.5, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationBlock extends StatelessWidget {
  const _LocationBlock({required this.title, required this.address, required this.icon});

  final String title;
  final String address;
  final IconData icon;

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
