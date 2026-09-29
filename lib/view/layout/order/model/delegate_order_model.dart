class DelegateOrdersModel {
  int? id;
  String? orderNo;
  int? resturantId;
  String? resturantName;
  List<ResturantAreas>? resturantAreas;
  String? resturantPhone;
  String? resturantLogo;
  String? resturantLocation;
  String? resturantLat;
  String? resturantLng;
  int? delegateId;
  String? delegateName;
  String? delegateMobile;
  String? delegateLogo;
  int? userId;
  String? userName;
  String? userMobile;
  String? userLocation;
  String? userLogo;
  String? status;
  String? type;
  String? scheduleDate;
  String? paymentType;
  String? paymentStatus;
  bool paymentRequired = false;
  num? deliveryPrice;
  num? tax;
  num? totalItemPrice;
  num? updatedTotalItemPrice;
  int? userAddressId;
  UserAddress? userAddress;
  List<DelegateItems>? delegateItems;
  String? createdAt;
  int? ordersCount;
  String? delegateFromOut;
  int? hasRatedBefore;
  int? hasCommissionedBefore;
  int? hasTransferedBefore;
  num? totalVendorOrders;
  num? totalDelegateOrders;
  num? serviceFees;
  num? vendorPercentage;
  num? appPercentage;
  num? appVendorPercentage;
  num? appDelegatePercentage;
  num? appToVendorPercentage;
  num? grandTotal;
  int? shippingId;
  String? description;
  String? fromLat;
  String? fromLng;
  String? toLat;
  String? toLng;
  String? fromAddress;
  String? toAddress;
  String? actualPrice;
  String? expectedPrice;
  String? delegateHasStatus;
  String? resturantVendorFcmId;
  String? resturantVendorDeviceToken;
  int? resturantVendorId;
  String? userFcmId;
  String? delegateFcmId;

  DelegateOrdersModel({
    this.id,
    this.orderNo,
    this.resturantId,
    this.resturantName,
    this.resturantAreas,
    this.resturantPhone,
    this.resturantLogo,
    this.resturantLocation,
    this.resturantLat,
    this.resturantLng,
    this.delegateId,
    this.delegateName,
    this.delegateMobile,
    this.delegateLogo,
    this.userId,
    this.userName,
    this.userMobile,
    this.userLocation,
    this.userLogo,
    this.status,
    this.type,
    this.scheduleDate,
    this.paymentType,
    this.paymentStatus,
    this.paymentRequired = false,
    this.deliveryPrice,
    this.tax,
    this.totalItemPrice,
    this.updatedTotalItemPrice,
    this.userAddressId,
    this.userAddress,
    this.delegateItems,
    this.createdAt,
    this.ordersCount,
    this.delegateFromOut,
    this.hasRatedBefore,
    this.hasCommissionedBefore,
    this.hasTransferedBefore,
    this.totalVendorOrders,
    this.totalDelegateOrders,
    this.serviceFees,
    this.vendorPercentage,
    this.appPercentage,
    this.appVendorPercentage,
    this.appDelegatePercentage,
    this.appToVendorPercentage,
    this.grandTotal,
    this.shippingId,
    this.description,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
    this.fromAddress,
    this.toAddress,
    this.actualPrice,
    this.expectedPrice,
    this.delegateHasStatus,
    this.resturantVendorFcmId,
    this.resturantVendorDeviceToken,
    this.resturantVendorId,
    this.userFcmId,
    this.delegateFcmId,
  });

  DelegateOrdersModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    orderNo = json['order_no'];
    resturantId = json['resturant_id'];
    resturantName = json['resturant_name'];
    if (json['resturant_areas'] != null) {
      resturantAreas = <ResturantAreas>[];
      json['resturant_areas'].forEach((v) {
        resturantAreas!.add(ResturantAreas.fromJson(v));
      });
    }
    resturantPhone = json['resturant_phone'];
    resturantLogo = json['resturant_logo'];
    resturantLocation = json['resturant_location'];
    resturantLat = json['resturant_lat'];
    resturantLng = json['resturant_lng'];
    delegateId = json['delegate_id'];
    delegateName = json['delegate_name'];
    delegateMobile = json['delegate_mobile'];
    delegateLogo = json['delegate_logo'];
    userId = json['user_id'];
    userName = json['user_name'];
    userMobile = json['user_mobile'];
    userLocation = json['user_location'];
    userLogo = json['user_logo'];
    status = json['status'];
    type = json['type'];
    scheduleDate = json['schedule_date'];
    paymentType = json['payment_type'];
    paymentStatus = json['payment_status'];
    paymentRequired = json['payment_required'] == true;
    deliveryPrice = json['delivery_price'];
    tax = json['tax'];
    totalItemPrice = json['total_item_price'];
    updatedTotalItemPrice = json['updated_total_item_price'];
    userAddressId = json['user_address_id'];
    userAddress = json['user_address'] != null ? UserAddress.fromJson(json['user_address']) : null;
    if (json['items'] != null) {
      delegateItems = <DelegateItems>[];
      json['items'].forEach((v) {
        delegateItems!.add(DelegateItems.fromJson(v));
      });
    }
    createdAt = json['created_at'];
    ordersCount = json['orders_count'];
    delegateFromOut = json['delegate_from_out'];
    hasRatedBefore = json['has_rated_before'];
    hasCommissionedBefore = json['has_commissioned_before'];
    hasTransferedBefore = json['has_transfered_before'];
    totalVendorOrders = json['total_vendor_orders'];
    totalDelegateOrders = json['total_delegate_orders'];
    serviceFees = json['service_fees'];
    vendorPercentage = json['vendor_percentage'];
    appPercentage = json['app_percentage'];
    appVendorPercentage = json['app_vendor_percentage'];
    appDelegatePercentage = json['app_delegate_percentage'];
    appToVendorPercentage = json['app_to_vendor_percentage'];
    grandTotal = json['grand_total'];
    shippingId = json['shipping_id'];
    description = json['description'];
    fromLat = json['from_lat'];
    fromLng = json['from_lng'];
    toLat = json['to_lat'];
    toLng = json['to_lng'];
    fromAddress = json['from_address'];
    toAddress = json['to_address'];
    actualPrice = json['actual_price'];
    expectedPrice = json['expected_price'];
    delegateHasStatus = json['delegate_has_status'];
    resturantVendorFcmId = json['resturant_vendor_fcm_id'];
    resturantVendorDeviceToken = json['resturant_vendor_device_token'];
    resturantVendorId = json['resturant_vendor_id'];
    userFcmId = json['user_fcm_id'];
    delegateFcmId = json['delegate_fcm_id'];
  }
  factory DelegateOrdersModel.fromPusher(Map<String, dynamic> pusherData) {
    return DelegateOrdersModel()
      ..id = pusherData['id']
      ..orderNo = pusherData['order_no']
      ..resturantId = pusherData['resturant_id']
      ..resturantName = pusherData['resturant_name']
      ..resturantAreas = pusherData['resturant_areas'] != null
          ? (pusherData['resturant_areas'] as List).map((v) => ResturantAreas.fromJson(v)).toList()
          : null
      ..resturantPhone = pusherData['resturant_phone']
      ..resturantLogo = pusherData['resturant_logo']
      ..resturantLocation = pusherData['resturant_location']
      ..resturantLat = pusherData['resturant_lat']
      ..resturantLng = pusherData['resturant_lng']
      ..delegateId = pusherData['delegate_id']
      ..delegateName = pusherData['delegate_name']
      ..delegateMobile = pusherData['delegate_mobile']
      ..delegateLogo = pusherData['delegate_logo']
      ..userId = pusherData['user_id']
      ..userName = pusherData['user_name']
      ..userMobile = pusherData['user_mobile']
      ..userLocation = pusherData['user_location']
      ..userLogo = pusherData['user_logo']
      ..status = pusherData['status']
      ..type = pusherData['type']
      ..scheduleDate = pusherData['schedule_date']
      ..paymentType = pusherData['payment_type']
      ..paymentStatus = pusherData['payment_status']
      ..paymentRequired = pusherData['payment_required'] == true
      ..deliveryPrice = pusherData['delivery_price']
      ..tax = pusherData['tax']
      ..totalItemPrice = pusherData['total_item_price']
      ..updatedTotalItemPrice = pusherData['updated_total_item_price']
      ..userAddressId = pusherData['user_address_id']
      ..userAddress = pusherData['user_address'] != null ? UserAddress.fromJson(pusherData['user_address']) : null
      ..delegateItems = pusherData['items'] != null
          ? (pusherData['items'] as List).map((v) => DelegateItems.fromJson(v)).toList()
          : null
      ..createdAt = pusherData['created_at']
      ..ordersCount = pusherData['orders_count']
      ..delegateFromOut = pusherData['delegate_from_out']
      ..hasRatedBefore = pusherData['has_rated_before']
      ..hasCommissionedBefore = pusherData['has_commissioned_before']
      ..hasTransferedBefore = pusherData['has_transfered_before']
      ..totalVendorOrders = pusherData['total_vendor_orders']
      ..totalDelegateOrders = pusherData['total_delegate_orders']
      ..serviceFees = pusherData['service_fees']
      ..vendorPercentage = pusherData['vendor_percentage']
      ..appPercentage = pusherData['app_percentage']
      ..appVendorPercentage = pusherData['app_vendor_percentage']
      ..appDelegatePercentage = pusherData['app_delegate_percentage']
      ..appToVendorPercentage = pusherData['app_to_vendor_percentage']
      ..grandTotal = pusherData['grand_total']
      ..shippingId = pusherData['shipping_id']
      ..description = pusherData['description']
      ..fromLat = pusherData['from_lat']
      ..fromLng = pusherData['from_lng']
      ..toLat = pusherData['to_lat']
      ..toLng = pusherData['to_lng']
      ..fromAddress = pusherData['from_address']
      ..toAddress = pusherData['to_address']
      ..actualPrice = pusherData['actual_price']
      ..expectedPrice = pusherData['expected_price']
      ..delegateHasStatus = pusherData['delegate_has_status']
      ..resturantVendorFcmId = pusherData['resturant_vendor_fcm_id']
      ..resturantVendorDeviceToken = pusherData['resturant_vendor_device_token']
      ..resturantVendorId = pusherData['resturant_vendor_id']
      ..userFcmId = pusherData['user_fcm_id']
      ..delegateFcmId = pusherData['delegate_fcm_id'];
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['order_no'] = orderNo;
    data['resturant_id'] = resturantId;
    data['resturant_name'] = resturantName;
    if (resturantAreas != null) {
      data['resturant_areas'] = resturantAreas!.map((v) => v.toJson()).toList();
    }
    data['resturant_phone'] = resturantPhone;
    data['resturant_logo'] = resturantLogo;
    data['resturant_location'] = resturantLocation;
    data['resturant_lat'] = resturantLat;
    data['resturant_lng'] = resturantLng;
    data['delegate_id'] = delegateId;
    data['delegate_name'] = delegateName;
    data['delegate_mobile'] = delegateMobile;
    data['delegate_logo'] = delegateLogo;
    data['user_id'] = userId;
    data['user_name'] = userName;
    data['user_mobile'] = userMobile;
    data['user_location'] = userLocation;
    data['user_logo'] = userLogo;
    data['status'] = status;
    data['type'] = type;
    data['schedule_date'] = scheduleDate;
    data['payment_type'] = paymentType;
    data['payment_status'] = paymentStatus;
    data['payment_required'] = paymentRequired;
    data['delivery_price'] = deliveryPrice;
    data['tax'] = tax;
    data['total_item_price'] = totalItemPrice;
    data['updated_total_item_price'] = updatedTotalItemPrice;
    data['user_address_id'] = userAddressId;
    if (userAddress != null) {
      data['user_address'] = userAddress!.toJson();
    }
    if (delegateItems != null) {
      data['items'] = delegateItems!.map((v) => v.toJson()).toList();
    }
    data['created_at'] = createdAt;
    data['orders_count'] = ordersCount;
    data['delegate_from_out'] = delegateFromOut;
    data['has_rated_before'] = hasRatedBefore;
    data['has_commissioned_before'] = hasCommissionedBefore;
    data['has_transfered_before'] = hasTransferedBefore;
    data['total_vendor_orders'] = totalVendorOrders;
    data['total_delegate_orders'] = totalDelegateOrders;
    data['service_fees'] = serviceFees;
    data['vendor_percentage'] = vendorPercentage;
    data['app_percentage'] = appPercentage;
    data['app_vendor_percentage'] = appVendorPercentage;
    data['app_delegate_percentage'] = appDelegatePercentage;
    data['app_to_vendor_percentage'] = appToVendorPercentage;
    data['grand_total'] = grandTotal;
    data['shipping_id'] = shippingId;
    data['description'] = description;
    data['from_lat'] = fromLat;
    data['from_lng'] = fromLng;
    data['to_lat'] = toLat;
    data['to_lng'] = toLng;
    data['from_address'] = fromAddress;
    data['to_address'] = toAddress;
    data['actual_price'] = actualPrice;
    data['expected_price'] = expectedPrice;
    data['delegate_has_status'] = delegateHasStatus;
    data['resturant_vendor_fcm_id'] = resturantVendorFcmId;
    data['resturant_vendor_device_token'] = resturantVendorDeviceToken;
    data['resturant_vendor_id'] = resturantVendorId;
    data['user_fcm_id'] = userFcmId;
    data['delegate_fcm_id'] = delegateFcmId;
    return data;
  }
}

class ResturantAreas {
  int? id;
  int? addedBy;
  int? resturantId;
  String? expectedDelivery;
  String? createdAt;
  String? updatedAt;
  int? areaId;
  String? type;

  ResturantAreas({
    this.id,
    this.addedBy,
    this.resturantId,
    this.expectedDelivery,
    this.createdAt,
    this.updatedAt,
    this.areaId,
    this.type,
  });

  ResturantAreas.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    addedBy = json['added_by'];
    resturantId = json['resturant_id'];
    expectedDelivery = json['expected_delivery'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    areaId = json['area_id'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['added_by'] = addedBy;
    data['resturant_id'] = resturantId;
    data['expected_delivery'] = expectedDelivery;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['area_id'] = areaId;
    data['type'] = type;
    return data;
  }
}

class UserAddress {
  int? id;
  String? areaName;
  String? mobile;
  String? apartmentNo;
  String? floorNo;
  String? streetName;
  String? badge;
  String? addressName;
  String? type;
  String? lat;
  String? lng;
  String? countryName;
  String? cityName;
  String? address;
  int? cityId;
  String? cityname;
  String? createdAt;

  UserAddress({
    this.id,
    this.areaName,
    this.mobile,
    this.apartmentNo,
    this.floorNo,
    this.streetName,
    this.badge,
    this.addressName,
    this.type,
    this.lat,
    this.lng,
    this.countryName,
    this.cityName,
    this.address,
    this.cityId,
    this.cityname,
    this.createdAt,
  });

  UserAddress.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    areaName = json['area_name'];
    mobile = json['mobile'];
    apartmentNo = json['apartment_no'];
    floorNo = json['floor_no'];
    streetName = json['street_name'];
    badge = json['badge'];
    addressName = json['address_name'];
    type = json['type'];
    lat = json['lat'];
    lng = json['lng'];
    countryName = json['country_name'];
    cityName = json['city_name'];
    address = json['address'];
    cityId = json['city_id'];
    cityname = json['cityname'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['area_name'] = areaName;
    data['mobile'] = mobile;
    data['apartment_no'] = apartmentNo;
    data['floor_no'] = floorNo;
    data['street_name'] = streetName;
    data['badge'] = badge;
    data['address_name'] = addressName;
    data['type'] = type;
    data['lat'] = lat;
    data['lng'] = lng;
    data['country_name'] = countryName;
    data['city_name'] = cityName;
    data['address'] = address;
    data['city_id'] = cityId;
    data['cityname'] = cityname;
    data['created_at'] = createdAt;
    return data;
  }
}

class DelegateItems {
  int? id;
  ResturantProduct? resturantProduct;
  int? resturantId;
  String? resturantName;
  String? resturantLat;
  String? resturantLng;
  String? resturantCityName;
  String? resturantDeliveryTime;
  int? orderId;
  num? price;
  int? qty;
  int? productFeature;
  String? productFeatureName;
  String? productClean;
  String? createdAt;
  num? minOrderPrice;
  num? total;
  num? updatedTotal;
  String? reasonUpdateTotal;

  DelegateItems({
    this.id,
    this.resturantProduct,
    this.resturantId,
    this.resturantName,
    this.resturantLat,
    this.resturantLng,
    this.resturantCityName,
    this.resturantDeliveryTime,
    this.orderId,
    this.price,
    this.qty,
    this.productFeature,
    this.productFeatureName,
    this.productClean,
    this.createdAt,
    this.minOrderPrice,
    this.total,
    this.updatedTotal,
    this.reasonUpdateTotal,
  });

  DelegateItems.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    resturantProduct = json['resturant_product'] != null ? ResturantProduct.fromJson(json['resturant_product']) : null;
    resturantId = json['resturant_id'];
    resturantName = json['resturant_name'];
    resturantLat = json['resturant_lat'];
    resturantLng = json['resturant_lng'];
    resturantCityName = json['resturant_city_name'];
    resturantDeliveryTime = json['resturant_delivery_time'];
    orderId = json['order_id'];
    price = json['price'];
    qty = json['qty'];
    productFeature = json['product_feature'];
    productFeatureName = json['product_feature_name'];
    productClean = json['product_clean'];
    createdAt = json['created_at'];
    minOrderPrice = json['min_order_price'];
    total = json['total'];
    updatedTotal = json['updated_total'];
    reasonUpdateTotal = json['reason_update_total'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    if (resturantProduct != null) {
      data['resturant_product'] = resturantProduct!.toJson();
    }
    data['resturant_id'] = resturantId;
    data['resturant_name'] = resturantName;
    data['resturant_lat'] = resturantLat;
    data['resturant_lng'] = resturantLng;
    data['resturant_city_name'] = resturantCityName;
    data['resturant_delivery_time'] = resturantDeliveryTime;
    data['order_id'] = orderId;
    data['price'] = price;
    data['qty'] = qty;
    data['product_feature'] = productFeature;
    data['product_feature_name'] = productFeatureName;
    data['product_clean'] = productClean;
    data['created_at'] = createdAt;
    data['min_order_price'] = minOrderPrice;
    data['total'] = total;
    data['updated_total'] = updatedTotal;
    data['reason_update_total'] = reasonUpdateTotal;
    return data;
  }
}

class ResturantProduct {
  int? id;
  int? vendorId;
  String? vendorName;
  int? resturantId;
  String? resturantName;
  String? productName;
  String? productDescription;
  List<Features>? features;
  num? productPrice;
  num? extraCombo;
  num? extraLarge;
  num? extraMedium;
  num? extraClean;
  num? extraClear;
  num? extraVacuim;
  int? categoryId;
  String? categoryName;
  int? subCategoryId;
  String? subCategoryName;
  int? productId;
  String? productTitle;
  String? status;
  int? hasClean;
  String? productImage;
  String? createdAt;

  ResturantProduct({
    this.id,
    this.vendorId,
    this.vendorName,
    this.resturantId,
    this.resturantName,
    this.productName,
    this.productDescription,
    this.features,
    this.productPrice,
    this.extraCombo,
    this.extraLarge,
    this.extraMedium,
    this.extraClean,
    this.extraClear,
    this.extraVacuim,
    this.categoryId,
    this.categoryName,
    this.subCategoryId,
    this.subCategoryName,
    this.productId,
    this.productTitle,
    this.status,
    this.hasClean,
    this.productImage,
    this.createdAt,
  });

  ResturantProduct.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    vendorId = json['vendor_id'];
    vendorName = json['vendor_name'];
    resturantId = json['resturant_id'];
    resturantName = json['resturant_name'];
    productName = json['product_name'];
    productDescription = json['product_description'];
    if (json['features'] != null) {
      features = <Features>[];
      json['features'].forEach((v) {
        features!.add(Features.fromJson(v));
      });
    }
    productPrice = json['product_price'];
    extraCombo = json['extra_combo'];
    extraLarge = json['extra_large'];
    extraMedium = json['extra_medium'];
    extraClean = json['extra_clean'];
    extraClear = json['extra_clear'];
    extraVacuim = json['extra_vacuim'];
    categoryId = json['category_id'];
    categoryName = json['category_name'];
    subCategoryId = json['sub_category_id'];
    subCategoryName = json['sub_category_name'];
    productId = json['product_id'];
    productTitle = json['product_title'];
    status = json['status'];
    hasClean = json['has_clean'];
    productImage = json['product_image'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['vendor_id'] = vendorId;
    data['vendor_name'] = vendorName;
    data['resturant_id'] = resturantId;
    data['resturant_name'] = resturantName;
    data['product_name'] = productName;
    data['product_description'] = productDescription;
    if (features != null) {
      data['features'] = features!.map((v) => v.toJson()).toList();
    }
    data['product_price'] = productPrice;
    data['extra_combo'] = extraCombo;
    data['extra_large'] = extraLarge;
    data['extra_medium'] = extraMedium;
    data['extra_clean'] = extraClean;
    data['extra_clear'] = extraClear;
    data['extra_vacuim'] = extraVacuim;
    data['category_id'] = categoryId;
    data['category_name'] = categoryName;
    data['sub_category_id'] = subCategoryId;
    data['sub_category_name'] = subCategoryName;
    data['product_id'] = productId;
    data['product_title'] = productTitle;
    data['status'] = status;
    data['has_clean'] = hasClean;
    data['product_image'] = productImage;
    data['created_at'] = createdAt;
    return data;
  }
}

class Features {
  int? id;
  String? name;
  String? createdAt;

  Features({this.id, this.name, this.createdAt});

  Features.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    createdAt = json['created_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['created_at'] = createdAt;
    return data;
  }
}
