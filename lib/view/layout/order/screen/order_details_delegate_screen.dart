import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../../../../helpers/images/app_images.dart';
import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/pusher_service/pusher_controller.dart';
import '../../../../helpers/theme/app_colors.dart';
import '../../../../helpers/theme/app_text_style.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/date_methods.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../../../helpers/utils/url_launcher_methods.dart';
import '../../../custom_widgets/api_response_widget/api_response_widget.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../../custom_widgets/custom_app_bar/custom_app_bar.dart';
import '../../../custom_widgets/custom_image/custom_image.dart';
import '../../../custom_widgets/dotted_decoration/dotted_decoration.dart';
import '../../../global/button/custom_elivated_botton.dart';
import '../../../global/chat/screen/admin_chat_screen.dart';
import '../../../global/chat/screen/chat_screen.dart';
import '../../../global/widget/delegate_order_detailes_item_widget.dart';
import '../../auth/controller/auth_controller.dart';
import '../../home/controller/delegate_home_controller.dart';
import '../controller/delegate_order_controller.dart';
import 'delivery_location_screen.dart';

class OrderDetailsDelegateScreenArgs {
  final int orderId;
  final bool? fromHome;
  const OrderDetailsDelegateScreenArgs({required this.fromHome, required this.orderId});
}

class OrderDetailsDelegateScreen extends StatefulWidget {
  static const String routeName = 'OrderDetailsDelegateScreen';
  final OrderDetailsDelegateScreenArgs args;
  const OrderDetailsDelegateScreen({super.key, required this.args});

  @override
  State<OrderDetailsDelegateScreen> createState() => _OrderDetailsDelegateScreenState();
}

class _OrderDetailsDelegateScreenState extends State<OrderDetailsDelegateScreen> {
  num? deliveryCoast;
  String? pusherStatus;
  String status = 'pending';
  int? pusherDelegateId;
  late PusherController _pusherController;

  // Saved reference
  @override
  void initState() {
    super.initState();
    _pusherController = context.read<PusherController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DelegateOrdersController>().initialDelegateSingleOrder();
      context
          .read<DelegateOrdersController>()
          .getDelegateSingleOrder(id: widget.args.orderId)
          .then(
            (value) => setState(() {
              status = context.read<DelegateOrdersController>().delegateSingleOrder?.status ?? '';
            }),
          );
    });
    _pusherController.addEventListener('delegate.updated', _handleDelegateUpdated);
  }

  void _handleDelegateUpdated(PusherEvent event) {
    try {
      // var jsonData = jsonDecode(event.data) as Map<String, dynamic>;
      if (mounted) {
        // context
        //     .read<DelegateOrdersController>()
        //     .getDelegateSingleOrder(id: widget.args.orderId);
        setState(() {
          // status = jsonData['order']['status']?.toString() ?? "";
          // pusherDelegateId = int.parse(jsonData['order']['delegate_id']);
          // var orderNo = jsonData['order']['order_no']?.toString();
          context.read<DelegateOrdersController>().initialDelegateSingleOrder();
          context.read<DelegateOrdersController>().getDelegateSingleOrder(id: widget.args.orderId);
          log('================> $pusherDelegateId');
          log('================> $pusherStatus');
          CommonMethods.showToast(message: '${AppLocaleKey.thereIsANewOrderWithStatus.tr()} ');
        });
      }
    } catch (e, stackTrace) {
      log('Error handling Pusher event: $e');
      log('Stack trace: $stackTrace');
    }
  }

  void updateStatus(String newStatus) {
    setState(() {
      status = newStatus;
      log('Status updated to =============================> $newStatus <=======================');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DelegateOrdersController>(
      builder: (context, delegateOrderController, _) {
        // final String status =
        //     delegateOrderController.delegateSingleOrder?.status ?? "";
        final bool isShipped = delegateOrderController.delegateSingleOrder?.type == 'shipping';
        deliveryCoast =
            (delegateOrderController.delegateSingleOrder?.deliveryPrice ?? 0) -
            (delegateOrderController.delegateSingleOrder?.appDelegatePercentage ?? 0);
        final String fromAddress;
        final String toAddress;
        final String fromLat;
        final String fromLan;
        final String toLat;
        final String toLan;

        final order = delegateOrderController.delegateSingleOrder;
        if (isShipped) {
          fromAddress = order?.fromAddress ?? '';
          toAddress = order?.toAddress ?? '';
          fromLat = order?.fromLat ?? '';
          fromLan = order?.fromLng ?? '';
          toLat = order?.toLat ?? '';
          toLan = order?.toLng ?? '';
        } else {
          fromAddress = " ${order?.resturantLocation ?? ""}";
          fromLat = order?.resturantLat ?? '';
          fromLan = order?.resturantLng ?? '';
          toLat = order?.userAddress?.lat ?? '';
          toLan = order?.userAddress?.lng ?? '';
          if (order?.delegateItems?.isNotEmpty == true) {
            toAddress = "${order?.userAddress?.address ?? ""} ,${order?.userAddress?.streetName ?? ""}";
          } else {
            toAddress = " ${order?.resturantLocation ?? ""} ";
          }
        }

        return Container(
          color: AppColor.scaffoldColor(context),
          child: ApiResponseWidget(
            apiResponse: delegateOrderController.delegateSingleOrderResponse,
            onReload: () => delegateOrderController.getDelegateSingleOrder(id: widget.args.orderId),
            isEmpty: delegateOrderController.delegateSingleOrder == null,
            child: Scaffold(
              extendBody: true,
              appBar: CustomAppBar(context, title: Text(AppLocaleKey.orderDetailes.tr())),
              body: RefreshIndicator(
                onRefresh: () async {
                  delegateOrderController.getDelegateSingleOrder(id: widget.args.orderId);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 21),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColor.textFormBorderColor(context)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    CustomImage(
                                      path: order?.userLogo == null || order?.userLogo == ''
                                          ? AppImages.userIcon
                                          : order?.userLogo ?? '',
                                      type: order?.userLogo == null || order?.userLogo == ''
                                          ? ImageType.svg
                                          : ImageType.network,
                                      height: 50,
                                      width: 50,
                                      radius: 25,
                                      fit: BoxFit.fill,
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start, // Ensure proper alignment
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  delegateOrderController.delegateSingleOrder?.userName ?? '',
                                                  style: AppTextStyle.textD16M(context),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  textWidthBasis: TextWidthBasis.longestLine,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              ((status != 'completed' &&
                                                          (status != 'pending' || status != 'another_delegate')) &&
                                                      delegateOrderController.delegateSingleOrder?.delegateId ==
                                                          context.read<AuthController>().profile?.id)
                                                  ? CustomElevatedButton(
                                                      size: 28,
                                                      onPressed: () {
                                                        UrlLauncherMethods.makePhoneCall(
                                                          delegateOrderController.delegateSingleOrder?.userMobile
                                                                  .toString() ??
                                                              '0',
                                                        );
                                                      },
                                                      imagePath: AppImages.callIcon,
                                                    )
                                                  : const SizedBox(),
                                              ((status != 'completed' &&
                                                          (status != 'pending' || status != 'another_delegate')) &&
                                                      delegateOrderController.delegateSingleOrder?.delegateId ==
                                                          context.read<AuthController>().profile?.id)
                                                  ? CustomElevatedButton(
                                                      size: 28,
                                                      onPressed: () {
                                                        NavigatorMethods.pushNamed(
                                                          context,
                                                          ChatScreen.routeName,
                                                          arguments: ChatScreenArgs(
                                                            senderDeviceToken:
                                                                delegateOrderController
                                                                    .delegateSingleOrder
                                                                    ?.delegateFcmId ??
                                                                '',
                                                            accountType: 'delegate',
                                                            isVendor: false,
                                                            receiverDeviceToken:
                                                                delegateOrderController
                                                                    .delegateSingleOrder
                                                                    ?.userFcmId ??
                                                                '',
                                                            senderName:
                                                                delegateOrderController
                                                                    .delegateSingleOrder
                                                                    ?.delegateName ??
                                                                '',
                                                            receiverName:
                                                                delegateOrderController.delegateSingleOrder?.userName ??
                                                                '',
                                                            vendorDeviceToken: '',
                                                            orderId:
                                                                'DC${delegateOrderController.delegateSingleOrder?.id}',
                                                            delegateId: context.read<AuthController>().profile?.id ?? 0,
                                                          ),
                                                        );
                                                      },
                                                      imagePath: AppImages.chatIcon,
                                                    )
                                                  : const SizedBox(),
                                              const SizedBox(width: 10),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: AppColor.lightMainAppColor(context),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
                                                  child: Text(
                                                    isShipped
                                                        ? AppLocaleKey.shippingOrder.tr()
                                                        : AppLocaleKey.restaurantOrder.tr(),
                                                    style: AppTextStyle.text16RS(context),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 15),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                AppLocaleKey.orderNumber.tr().replaceAll(
                                                  '{}',
                                                  '${delegateOrderController.delegateSingleOrder?.orderNo ?? 0}',
                                                ),
                                                style: AppTextStyle.text14RG(context),
                                              ),
                                              Row(
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5),
                                                    child: Icon(
                                                      Icons.access_time,
                                                      size: 17,
                                                      color: AppColor.greyColor(context),
                                                    ),
                                                  ),
                                                  Text(
                                                    DateMethods.formatToDate(order?.createdAt?.toString() ?? ''),
                                                    style: AppTextStyle.text14RG(context),
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    DateMethods.formatToTime(order?.createdAt?.toString() ?? ''),
                                                    style: AppTextStyle.text14RG(context),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              //===============================================================================
                              Container(decoration: const DottedDecoration(strokeWidth: 0.7, dash: [7, 5])),
                              //====================================== order location==========================================
                              delegateOrderController.delegateSingleOrder?.delegateItems != null &&
                                          delegateOrderController.delegateSingleOrder?.delegateId ==
                                              context.read<AuthController>().profile?.id ||
                                      delegateOrderController.delegateSingleOrder?.delegateId == null
                                  ? InkWell(
                                      onTap: () {
                                        NavigatorMethods.pushNamed(
                                          context,
                                          DeliveryLocationScreen.routeName,
                                          arguments: DeliveryLocationArgs(
                                            lat: double.parse(fromLat),
                                            lng: double.parse(fromLan),
                                          ),
                                        );
                                      },
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 15),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 17),
                                            child: Text(
                                              AppLocaleKey.receivingAddress.tr(),
                                              style: AppTextStyle.text16MS(context),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          delegateOrderController.delegateSingleOrder?.delegateItems?.isEmpty == true
                                              ? Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                                  child: Row(
                                                    children: [
                                                      const CustomImage(
                                                        path: AppImages.locationIcon,
                                                        type: ImageType.svg,
                                                      ),
                                                      const SizedBox(width: 5),
                                                      Expanded(
                                                        child: Text(
                                                          fromAddress,

                                                          // "${delegateOrderController.delegateSingleOrder?.delegateItems?.first.resturantCityName ?? ""}\t- \t${delegateOrderController.delegateSingleOrder?.resturantLocation ?? ""}",
                                                          style: AppTextStyle.text16RG(context),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              : const SizedBox(),
                                          order?.delegateItems?.isEmpty == true
                                              ? const SizedBox()
                                              : Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                                  child: Row(
                                                    children: [
                                                      const CustomImage(
                                                        path: AppImages.locationIcon,
                                                        type: ImageType.svg,
                                                      ),
                                                      const SizedBox(width: 5),
                                                      Expanded(
                                                        child: Text(
                                                          fromAddress,

                                                          // "${delegateOrderController.delegateSingleOrder?.delegateItems?.first.resturantCityName ?? ""}\t- \t${delegateOrderController.delegateSingleOrder?.resturantLocation ?? ""}",
                                                          style: AppTextStyle.text16RG(context),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                        ],
                                      ),
                                    )
                                  : const SizedBox(),
                              const SizedBox(height: 10),

                              //====================================== delivery location==========================================
                              delegateOrderController.delegateSingleOrder?.delegateId ==
                                          context.read<AuthController>().profile?.id ||
                                      delegateOrderController.delegateSingleOrder?.delegateId == null
                                  ? InkWell(
                                      onTap: () {
                                        NavigatorMethods.pushNamed(
                                          context,
                                          DeliveryLocationScreen.routeName,
                                          arguments: DeliveryLocationArgs(
                                            lat: double.parse(toLat),
                                            lng: double.parse(toLan),
                                          ),
                                        );
                                      },
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 17),
                                            child: Text(
                                              AppLocaleKey.deliveryLocation.tr(),
                                              style: AppTextStyle.text16MS(context),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          //Location
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            child: Row(
                                              children: [
                                                const CustomImage(path: AppImages.locationIcon, type: ImageType.svg),
                                                const SizedBox(width: 5),
                                                Expanded(child: Text(toAddress, style: AppTextStyle.text16RG(context))),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                        ],
                                      ),
                                    )
                                  : const SizedBox(),

                              delegateOrderController.delegateSingleOrder?.delegateId ==
                                          context.read<AuthController>().profile?.id ||
                                      delegateOrderController.delegateSingleOrder?.delegateId == null
                                  ? Divider(thickness: 0.2, color: AppColor.textFormColor(context))
                                  : const SizedBox(),
                              delegateOrderController.delegateSingleOrder?.resturantId != null && !isShipped
                                  ? Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          CustomImage(
                                            path: delegateOrderController.delegateSingleOrder?.resturantLogo ?? '',
                                            type: ImageType.network,
                                            height: 50,
                                            width: 50,
                                            radius: 24,
                                            fit: BoxFit.fill,
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                              child: Text(
                                                delegateOrderController.delegateSingleOrder?.resturantName ?? '',
                                                style: AppTextStyle.textD16M(context),
                                              ),
                                            ),
                                          ),
                                          ((status != 'completed' &&
                                                      (status != 'pending' || status != 'another_delegate')) &&
                                                  delegateOrderController.delegateSingleOrder?.delegateId ==
                                                      context.read<AuthController>().profile?.id)
                                              ? CustomElevatedButton(
                                                  onPressed: () {
                                                    UrlLauncherMethods.makePhoneCall(
                                                      delegateOrderController.delegateSingleOrder?.resturantPhone ??
                                                          '0',
                                                    );
                                                  },
                                                  imagePath: AppImages.callIcon,
                                                )
                                              : const SizedBox(),
                                          ((status != 'completed' &&
                                                      (status != 'pending' || status != 'another_delegate')) &&
                                                  delegateOrderController.delegateSingleOrder?.delegateId ==
                                                      context.read<AuthController>().profile?.id)
                                              ? CustomElevatedButton(
                                                  onPressed: () {
                                                    final data = delegateOrderController.delegateSingleOrder;
                                                    NavigatorMethods.pushNamed(
                                                      context,
                                                      AdminChatScreen.routeName,
                                                      arguments: AdminChatScreenArgs(
                                                        senderId: data?.delegateId.toString() ?? '',
                                                        receiverId: data?.resturantVendorId.toString() ?? '',
                                                        receiverDeviceToken: data?.resturantVendorFcmId ?? '',
                                                        receiverName: data?.resturantName ?? '',
                                                        senderName: data?.delegateName ?? '',
                                                        senderDeviceToken: data?.delegateFcmId ?? '',
                                                        accountType: 'delegate',
                                                        isToVendor: true,
                                                        vendorDeviceToken: data?.resturantVendorDeviceToken ?? '',
                                                      ),
                                                    );
                                                    // NavigatorMethods
                                                    //     .pushNamed(
                                                    //   context,
                                                    //   ChatScreen.routeName,
                                                    //   arguments: ChatScreenArgs(
                                                    //       senderDeviceToken:
                                                    //           delegateOrderController
                                                    //                   .delegateSingleOrder
                                                    //                   ?.delegateFcmId ??
                                                    //               "",
                                                    //       accountType:
                                                    //           "delegate",
                                                    //       isVendor: true,
                                                    //       receiverDeviceToken:
                                                    //           delegateOrderController
                                                    //                   .delegateSingleOrder
                                                    //                   ?.resturantVendorFcmId ??
                                                    //               "",
                                                    //       senderName: delegateOrderController
                                                    //               .delegateSingleOrder
                                                    //               ?.delegateName ??
                                                    //           "",
                                                    //       receiverName:
                                                    //           delegateOrderController
                                                    //                   .delegateSingleOrder
                                                    //                   ?.userName ??
                                                    //               "",
                                                    //       vendorDeviceToken:
                                                    //           delegateOrderController
                                                    //                   .delegateSingleOrder
                                                    //                   ?.resturantVendorDeviceToken ??
                                                    //               "",
                                                    //       delegateId: context
                                                    //               .read<AuthController>()
                                                    //               .profile
                                                    //               ?.id ??
                                                    //           0,
                                                    //       orderId: "VD${delegateOrderController.delegateSingleOrder?.id}"),
                                                    // );
                                                  },
                                                  imagePath: AppImages.chatIcon,
                                                )
                                              : const SizedBox(),
                                        ],
                                      ),
                                    )
                                  : const SizedBox(),

                              delegateOrderController.delegateSingleOrder?.delegateId != null ||
                                      delegateOrderController.delegateSingleOrder?.delegateId == null
                                  ? Divider(thickness: 0.2, color: AppColor.textFormColor(context))
                                  : const SizedBox(),
                              if (delegateOrderController.delegateSingleOrder?.delegateItems?.isNotEmpty == true) ...[
                                ...List.generate(
                                  delegateOrderController.delegateSingleOrder?.delegateItems?.length ?? 0,
                                  (orderIndex) => OrderDelegateDetailsItemWidget(
                                    items: delegateOrderController.delegateSingleOrder?.delegateItems?[orderIndex],
                                  ),
                                ),
                              ],
                              isShipped
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                      child: Text(order?.description ?? '', style: AppTextStyle.text16MS(context)),
                                    )
                                  : const SizedBox(),
                              Divider(thickness: 0.2, color: AppColor.textFormColor(context)),

                              //============================ Pricing ================================
                              if (delegateOrderController.delegateSingleOrder?.paymentType == 'cash') ...[
                                !isShipped
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              AppLocaleKey.secondaryTotal.tr(),
                                              style: AppTextStyle.text18MG(context),
                                            ),
                                            Text(
                                              AppLocaleKey.pound.tr().replaceAll(
                                                '{}',
                                                '${delegateOrderController.delegateSingleOrder?.updatedTotalItemPrice ?? delegateOrderController.delegateSingleOrder?.totalItemPrice}',
                                              ),
                                              style: AppTextStyle.text16RG(context),
                                            ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox(),
                                !isShipped
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: const DottedDecoration(strokeWidth: 0.7, dash: [7, 5]),
                                      )
                                    : const SizedBox(),
                                !isShipped
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(AppLocaleKey.serviceFee.tr(), style: AppTextStyle.text18MG(context)),
                                            Text(
                                              AppLocaleKey.pound.tr().replaceAll(
                                                '{}',
                                                '${delegateOrderController.delegateSingleOrder?.serviceFees}',
                                              ),
                                              style: AppTextStyle.text16RG(context),
                                            ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox(),
                                !isShipped
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: const DottedDecoration(strokeWidth: 0.7, dash: [7, 5]),
                                      )
                                    : const SizedBox(),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(AppLocaleKey.deliveryCost.tr(), style: AppTextStyle.text18MG(context)),
                                      Text(
                                        AppLocaleKey.pound.tr().replaceAll(
                                          '{}',
                                          deliveryCoast?.toStringAsFixed(2).toString() ?? '',
                                        ),
                                        //  "${delegateOrderController.delegateSingleOrder?.deliveryPrice?.toStringAsFixed(0)}"),
                                        style: AppTextStyle.text16RG(context),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(AppLocaleKey.appPercentage.tr(), style: AppTextStyle.text18MG(context)),
                                      Text(
                                        AppLocaleKey.pound.tr().replaceAll(
                                          '{}',
                                          '${delegateOrderController.delegateSingleOrder?.appDelegatePercentage?.toStringAsFixed(2)}',
                                        ),
                                        style: AppTextStyle.text16RG(context),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: const DottedDecoration(strokeWidth: 0.7, dash: [7, 5]),
                                ),
                                !isShipped
                                    ? Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(AppLocaleKey.addedValue.tr(), style: AppTextStyle.text18MG(context)),
                                            Text(
                                              AppLocaleKey.pound.tr().replaceAll(
                                                '{}',
                                                '${delegateOrderController.delegateSingleOrder?.tax}',
                                              ),
                                              style: AppTextStyle.text16RG(context),
                                            ),
                                          ],
                                        ),
                                      )
                                    : const SizedBox(),
                                !isShipped
                                    ? Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: const DottedDecoration(strokeWidth: 0.7, dash: [7, 5]),
                                      )
                                    : const SizedBox(),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(AppLocaleKey.totalPrice.tr(), style: AppTextStyle.text18BS(context)),
                                      Text(
                                        AppLocaleKey.pound.tr().replaceAll(
                                          '{}',
                                          (delegateOrderController.delegateSingleOrder?.grandTotal ?? 0)
                                              .toStringAsFixed(0),
                                        ),
                                        style: AppTextStyle.text18BS(context),
                                      ),
                                    ],
                                  ),
                                ),

                                // Padding(
                                //   padding: const EdgeInsets.symmetric(
                                //       horizontal: 16, vertical: 10),
                                //   child: Row(
                                //     mainAxisAlignment:
                                //         MainAxisAlignment.spaceBetween,
                                //     children: [
                                //       Text(
                                //         AppLocaleKey.totalPrice.tr(),
                                //         style: AppTextStyle.text18BS(context),
                                //       ),
                                //       Text(
                                //         AppLocaleKey.pound.tr().replaceAll(
                                //             "{}",
                                //             "${(delegateOrderController.delegateSingleOrder?.totalItemPrice ?? 0) + (delegateOrderController.delegateSingleOrder?.deliveryPrice ?? 0)}"),
                                //         style: AppTextStyle.text18BS(context),
                                //       ),
                                //     ],
                                //   ),
                                // ),
                                Divider(thickness: 0.2, color: AppColor.textFormColor(context)),
                              ],
                              if (delegateOrderController.delegateSingleOrder?.paymentType != 'cash') ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(AppLocaleKey.deliveryCost.tr(), style: AppTextStyle.text18MG(context)),
                                      Text(
                                        AppLocaleKey.pound.tr().replaceAll(
                                          '{}',
                                          '${delegateOrderController.delegateSingleOrder?.deliveryPrice?.toStringAsFixed(2)}',
                                        ),
                                        style: AppTextStyle.text16RG(context),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: const DottedDecoration(strokeWidth: 0.7, dash: [7, 5]),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(AppLocaleKey.appPercentage.tr(), style: AppTextStyle.text18MG(context)),
                                      Text(
                                        AppLocaleKey.pound.tr().replaceAll(
                                          '{}',
                                          '${delegateOrderController.delegateSingleOrder?.appPercentage?.toStringAsFixed(0)}',
                                        ),
                                        style: AppTextStyle.text16RG(context),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: const DottedDecoration(strokeWidth: 0.7, dash: [7, 5]),
                                ),
                              ],

                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                child: Text(AppLocaleKey.paymentMethod.tr(), style: AppTextStyle.text16BS(context)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    Container(
                                      height: 24,
                                      width: 5,
                                      decoration: BoxDecoration(
                                        color: AppColor.mainAppColor(context),
                                        borderRadius: BorderRadius.horizontal(
                                          left: context.locale.languageCode == 'ar'
                                              ? const Radius.circular(5)
                                              : const Radius.circular(0),
                                          right: context.locale.languageCode == 'ar'
                                              ? const Radius.circular(0)
                                              : const Radius.circular(5),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    CustomImage(
                                      path: delegateOrderController.delegateSingleOrder?.paymentType == 'cash'
                                          ? AppImages.cashIcon
                                          : delegateOrderController.delegateSingleOrder?.paymentType == 'online'
                                          ? AppImages.visaIcon
                                          : delegateOrderController.delegateSingleOrder?.paymentType == 'v_cash'
                                          ? AppImages.vfCash
                                          : delegateOrderController.delegateSingleOrder?.paymentType == 'wallet'
                                          ? AppImages.payWalletIcon.tr()
                                          : '',
                                      type: ImageType.svg,
                                      height: 20,
                                      color: AppColor.mainAppColor(context),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      delegateOrderController.delegateSingleOrder?.paymentType == 'cash'
                                          ? AppLocaleKey.cash.tr()
                                          : delegateOrderController.delegateSingleOrder?.paymentType == 'online'
                                          ? AppLocaleKey.visa.tr()
                                          : delegateOrderController.delegateSingleOrder?.paymentType == 'v_cash'
                                          ? AppLocaleKey.digitalWalletAndInstaPay.tr()
                                          : delegateOrderController.delegateSingleOrder?.paymentType == 'wallet'
                                          ? AppLocaleKey.appWalletBalance.tr()
                                          : '',
                                      style: AppTextStyle.text16BM(context),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              //==========================  buttton  ================================
                            ],
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
              bottomNavigationBar: buildBottomNavigationBar(
                delegateOrderController.delegateSingleOrder?.status ?? '',
                delegateOrderController,
                context,
                isShipped,
                pusherDelegateId ?? delegateOrderController.delegateSingleOrder?.delegateId,
                delegateOrderController.delegateSingleOrder?.delegateHasStatus,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildBottomNavigationBar(
    String status,
    DelegateOrdersController delegateOrderController,
    BuildContext context,
    bool isShipped,
    int? orderDelegateId,
    String? delegateHasStatus,
  ) {
    final delegateSingleOrder = delegateOrderController.delegateSingleOrder;
    final currentUserId = context.read<AuthController>().profile?.id;

    bool isCurrentUserDelegate() => orderDelegateId == currentUserId;

    Widget buildButton({
      required String text,
      required VoidCallback onPressed,
      Color? color,
      TextStyle? style,
      EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 23),
    }) {
      return Padding(
        padding: padding,
        child: CustomButton(
          color: color ?? AppColor.lightGreyColor(context),
          text: text,
          style: style ?? AppTextStyle.text18BS(context),
          onPressed: onPressed,
        ),
      );
    }

    Widget buildAcceptRejectButtons() {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: buildButton(
                text: AppLocaleKey.accept.tr(),
                style: AppTextStyle.text18BW(context),
                color: AppColor.mainAppColor(context),
                onPressed: () => delegateOrderController.acceptOrDeclineOrder(
                  orderId: delegateSingleOrder?.id ?? 0,
                  status: 'accept',
                  onSuccess: () {
                    // updateStatus("pusher_accepted");
                    if (mounted) {
                      callBackground();
                    }
                    delegateOrderController.getDelegateSingleOrder(id: widget.args.orderId);
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: buildButton(
                text: AppLocaleKey.reject.tr(),
                color: const Color(0xffEEEEEE),
                style: AppTextStyle.text18MS(context),
                onPressed: () => delegateOrderController.acceptOrDeclineOrder(
                  orderId: delegateSingleOrder?.id ?? 0,
                  status: 'declined',
                  onSuccess: () {
                    // updateStatus("declined");
                    if (mounted) {
                      callBackground();
                    }
                    delegateOrderController.getDelegateSingleOrder(id: widget.args.orderId);
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildOrderButton() {
      final text = isShipped
          ? AppLocaleKey.orderReceivedFrom.tr().replaceAll('{}', AppLocaleKey.theCustomer.tr())
          : AppLocaleKey.orderReceivedFrom.tr().replaceAll('{}', AppLocaleKey.theResturant.tr());
      return buildButton(
        text: text,
        color: AppColor.mainAppColor(context),
        style: AppTextStyle.text18BW(context),
        onPressed: () => delegateOrderController.receivedOrderDelegate(
          orderId: delegateSingleOrder?.id ?? 0,
          onSuccess: () {
            //status = "shipped";
            // updateStatus("shipped");
            // updateStatus("pusher_shipped");
            if (mounted) {
              callBackground();
            }

            // Update state
            delegateOrderController.getDelegateSingleOrder(id: delegateSingleOrder?.id ?? 0);
          },
        ),
      );
    }

    Widget buildCompleteOrderButton() {
      return buildButton(
        text: AppLocaleKey.deliverOrderToCustomer.tr(),
        color: AppColor.greenColor(context),
        style: AppTextStyle.text18BW(context),
        onPressed: () => delegateOrderController.completeOrderDelegate(
          orderId: delegateSingleOrder?.id ?? 0,
          onSuccess: () {
            // status = "completed";
            //  updateStatus("pusher_completed");
            if (mounted) {
              callBackground();
            }

            delegateOrderController.getDelegateSingleOrder(id: delegateSingleOrder?.id ?? 0);
          },
        ),
      );
    }

    Widget buildCashPaymentButton() {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: buildButton(
                text: AppLocaleKey.deliveredToCustomer.tr(),
                style: AppTextStyle.text16BS(context),
                onPressed: () {},
              ),
            ),
          ],
        ),
      );
    }

    // Decision tree logic
    if ((status == 'pending' || status == 'another_delegate') && delegateHasStatus == null) {
      return buildAcceptRejectButtons();
    }

    if ((status == 'pending' || status == 'another_delegate') && delegateHasStatus != 'declined') {
      return buildButton(
        text: AppLocaleKey.waitToBeAccepted.tr(),
        onPressed: () => delegateOrderController.getDelegateSingleOrder(id: delegateSingleOrder?.id ?? 0),
      );
    }
    if ((status == 'pending' || status == 'another_delegate') && delegateHasStatus == 'declined') {
      return buildButton(text: AppLocaleKey.orderCancelled.tr(), onPressed: () {});
    }

    // if (status == "pusher_accepted") {
    //   return buildOrderButton();
    // }

    if ((status == 'pusher_accepted') || (status == 'accepted' && isCurrentUserDelegate())) {
      return buildOrderButton();
    }

    if ((status == 'pusher_shipped') || (status == 'shipped' && isCurrentUserDelegate())) {
      return buildCompleteOrderButton();
    }

    if ((status == 'pusher_completed') ||
        (status == 'completed' && delegateSingleOrder?.delegateFromOut != null && isCurrentUserDelegate())) {
      if (delegateSingleOrder?.delegateFromOut == 'out_resturant' &&
          delegateSingleOrder?.paymentType == 'cash' &&
          delegateSingleOrder?.hasTransferedBefore == 0) {
        return buildCashPaymentButton();
      } else {
        return buildButton(text: AppLocaleKey.deliveredOrderToCustomer.tr(), onPressed: () {});
      }
    }

    if (status == 'another_delegate' && isCurrentUserDelegate()) {
      return buildButton(text: AppLocaleKey.anotherDelegateReceivedOrder.tr(), onPressed: () {});
    }

    if ((status == 'pusher_completed') || (status == 'completed' && isCurrentUserDelegate())) {
      return buildButton(text: AppLocaleKey.deliveredOrderToCustomer.tr(), onPressed: () {});
    }
    if (status == 'cancelled') {
      return buildButton(text: AppLocaleKey.orderCanceled.tr(), onPressed: () {});
    }
    if (status == 'declined') {
      return buildButton(text: AppLocaleKey.canceled.tr(), onPressed: () {});
    }

    return buildButton(
      // color: AppColor.yellowColor(context),
      text: AppLocaleKey.acceptedByAnotherDelegate.tr(),
      onPressed: () {},
    );
  }

  Future<void> callBackground() async {
    if (!mounted) return;

    if (widget.args.fromHome == true) {
      log('Home Order');
      final homeController = Provider.of<HomeDelegateController>(context, listen: false);

      try {
        await Future.wait([
          homeController.getPendingDelegateHomeOrders(),
          homeController.getCurrentDelegateHomeOrders(),
        ]);
      } catch (e) {
        log('Error loading home orders: $e');
      }
    } else {
      log('not in Home Order');
      final orderController = Provider.of<DelegateOrdersController>(context, listen: false);

      try {
        // Initialize states first
        orderController.initialDelegateCompletedOrders();
        orderController.initialDelegateOngoingOrders();
        orderController.initialDelegateWaitingOrders();

        await Future.wait([
          orderController.getDelegateWaitingOrders(),
          orderController.getDelegateOngoingOrders(),
          orderController.getDelegateCompletedOrders(),
        ]);
      } catch (e) {
        log('Error loading orders: $e');
      }
    }
  }
}
