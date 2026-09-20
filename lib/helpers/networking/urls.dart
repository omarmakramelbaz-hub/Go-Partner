class Urls {
  static const String testBlueCarImage =
      'https://images.pexels.com/photos/170811/pexels-photo-170811.jpeg?cs=srgb&amp;dl=pexels-mike-b-170811.jpg&amp;fm=jpg';
  static const String testWhiteCarImage =
      'https://images.pexels.com/photos/116675/pexels-photo-116675.jpeg?cs=srgb&amp;dl=pexels-mike-b-116675.jpg&amp;fm=jpg';
  static const String testCarLogoImage = 'https://cdn.worldvectorlogo.com/logos/bmw-logo.svg';
  static const String testUserImage =
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSLlsHCzHU2GndYsMJQscyixYSlDVggHDzbXtXSuEmLAc309Z-6e1TUhHJFCLCw40Kicw0';
  static const String testAppleLogo = 'https://justcreative.com/wp-content/uploads/2022/01/Apple-Logo-600x400.png';
  static const String testNoonLogo =
      'https://www.elmin7a.com/wp-content/uploads/2021/08/noon-egypt-jobs-customer-service-agent.png';
  static const String testVideo = 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';
  //  static const String baseUrl =
  //      'https://backend.smartvision4p.com/faskhaNinja/public/api/';

  //! ===================> Live Api <=================== !//
  static const String baseUrl = 'https://fasakhaninja.com/api/';

  //! ===================> vendor <=================== !//
  static const String profile = '${baseUrl}profile';
  static const String login = '${baseUrl}login';
  static const String changeStatus = '${baseUrl}vendor/resturants';
  static const String currentHomeOrders = '${baseUrl}vendor/orders?home=yes&status=current';
  static const String currentOrdersHome = '${baseUrl}vendor/orders?status=pending&home=yes';
  static const String pendingOrdersHome = '${baseUrl}vendor/orders?home=yes&status=pending';
  // static const String currentOrders = '${baseUrl}vendor/orders?status=pending';
  // static const String ongoingOrders = '${baseUrl}vendor/orders?status=accepted';
  static const String waitingOrders = '${baseUrl}vendor/orders?status=pending';
  static const String currentOrders = '${baseUrl}vendor/orders?status=current';
  static const String completedOrders = '${baseUrl}vendor/orders?status=completed';
  static const String vendorNotifications = '${baseUrl}user/notifications';
  static const String vendorWallet = '${baseUrl}user/get/charging/wallet';
  static const String vendorChargingWallet = '${baseUrl}user/charging/wallet';
  static const String vendorHelp = '${baseUrl}help';
  static const String vendorSetting = '${baseUrl}setting';
  static const String vendorStoreContact = '${baseUrl}store-contact';
  static const String vendorLogout = '${baseUrl}logout';
  static const String vendorChangePassword = '${baseUrl}change-password';
  static const String orderDetails = '${baseUrl}vendor/orders/';
  static const String fromOrOut = '${baseUrl}vendor/orders/';
  static const String updateOrderStatus = '${baseUrl}vendor/update/orders/';
  static const String createItem = '${baseUrl}vendor/items';
  static const String getItems = '${baseUrl}vendor/items';
  static const String updateItem = '${baseUrl}vendor/items/';
  static const String copeMainMenu = '${baseUrl}vendor/copy/items';
  static const String getCategories = '${baseUrl}categorys';
  static const String productClasses = '${baseUrl}products';
  static const String singleProduct = '${baseUrl}products/';
  static const String vendorSingleProduct = '${baseUrl}vendor/menu/item/';
  static const String deleteItem = '${baseUrl}vendor/items/';
  static const String wallet = '${baseUrl}user/get/charging/wallet';
  static const String chargingWallet = '${baseUrl}user/charging/wallet';
  static const String reports = '${baseUrl}vendor/reports';
  static const String updateVendorProfile = '${baseUrl}update-profile/vendor';
  static const String updateVendorLocation = '${baseUrl}vendor/update/';
  static const String ongoingOrdersHome = '${baseUrl}vendor/orders?status=accepted&home=yes';
  static const String vendorTransferOrderPrice = '${baseUrl}vendor/transfer/order/';
  static const String updateDeliveryTime = '${baseUrl}vendor/resturants/';
  static String updateOrder(int orderId) => '${baseUrl}vendor/update/orders/$orderId/total/price';
  static const String checkMonyTransfer = '${baseUrl}check/user/transfer';
  static const String transferWallet = '${baseUrl}transfer/wallet';
  static const String changePhoneNumber = '${baseUrl}update/phone';
  static const String delegateOrders = '${baseUrl}shipping/get/orders';
  static const String delegateShippingOrderDetails = '${baseUrl}shipping/orders';
  static const String delegateOnMap = '${baseUrl}shipping/search/delegates';
  static const String createNewShipping = '${baseUrl}shipping/new/order';
  static const String riseActualPrice = '${baseUrl}shipping/order/update/actual/price';
  static const String acceptOrDeclinedDelegate = '${baseUrl}shipping/accept/delegate';
  static String getAcceptedDelegates(int orderId) => '${baseUrl}shipping/$orderId/accepted/delegates';
  static const String cancelOrder = '${baseUrl}user/cancel/order';

  //! ===================> Delegate <=================== !//
  static const String delegateConnectedUpdate = '${baseUrl}delegate/connected/update';
  static const String delegateHomeCurrentOrders = '${baseUrl}delegate/orders?status=pending';
  static const String delegateCurrentOrdersHome = '${baseUrl}delegate/orders?status=pending&home=yes';
  static const String delegateOngoingOrdersHome = '${baseUrl}delegate/orders?status=accepted&home=yes';
  static const String delegateCompletedOrders = '${baseUrl}delegate/orders?status=completed';
  static const String delegateOrderDetails = '${baseUrl}delegate/orders/';
  static const String delegateHomeCurrentOrder = '${baseUrl}delegate/orders?home=yes&status=current';
  static const String delegateAcceptDecline = '${baseUrl}delegate/accept_decline/orders/';
  static const String compleatOrderDelegate = '${baseUrl}delegate/orders/';
  static const String delegateCurrentOrders = '${baseUrl}delegate/orders?status=current';
  static const String delegateReports = '${baseUrl}delegate/reports';
  static const String delegateHomePendingOrders = '${baseUrl}delegate/orders?home=yes&status=pending';

  static const String delegateTransferOrderPrice = '${baseUrl}delegate/transfer/order/';
  static const String delegateReceivedOrder = '${baseUrl}delegate/accept_decline/orders/';
  //  static const String profile = '${baseUrl}profile';
  //    static const String login = '${baseUrl}login';
  //    static const String changeStatus = '${baseUrl}vendor/resturants';
  //    static const String currentOrdersHome = '${baseUrl}vendor/orders?status=pending&home=yes';
  //    static const String vendorNotifications = '${baseUrl}user/notifications';
  //    static const String vendorWallet = '${baseUrl}user/get/charging/wallet';
  //    static const String vendorChargingWallet = '${baseUrl}user/charging/wallet';
  //    static const String vendorHelp = '${baseUrl}help';
  //    static const String vendorSetting = '${baseUrl}setting';
  //    static const String vendorStoreContact = '${baseUrl}store-contact';
  //     static const String vendorLogout = '${baseUrl}logout';
  //     static const String vendorChangePassword = '${baseUrl}change-password';
  //! ===================> Delegate <=================== !//
  //static const String delegateConnectedUpdate = '${baseUrl}delegate/connected/update';
  static const String delegateNotifications = '${baseUrl}user/notifications';
  static const String delegateUpdateProfile = '${baseUrl}update-profile/delegate';
  static const String areas = '${baseUrl}areas';
  static const String updatePosition = '${baseUrl}update/position';
  static const String waitingDelegateOrders = '${baseUrl}delegate/orders?status=pending';
  static const String vendorSignUp = '${baseUrl}signup';
  static const String partnerApplications = '${baseUrl}partner-applications';
  static const String partnerApplicationStatus = '${baseUrl}partner-applications/status';
  static const String professions = '${baseUrl}professions';
  static const String contract = '${baseUrl}contract/';
  static const String deleteAccount = '${baseUrl}user/delete_account';

  //! ===================> Live Api <=================== !//
}
