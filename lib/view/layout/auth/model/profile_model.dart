class ProfileModel {
  int? id;
  String? name;
  String? email;
  String? accountType;
  String? appScope;
  bool? isGoPartner;
  String? partnerProfessionKey;
  String? partnerProfessionNameAr;
  String? partnerProfessionNameEn;
  int? partnerWorkRadiusKm;
  String? partnerApplicationStatus;
  int? countryCode;
  String? mobile;
  String? fcmId;
  String? gender;
  String? lat;
  String? lng;
  String? countryName;
  String? cityName;
  String? address;
  String? mobileCode;
  int? areaId;
  String? areaTitle;
  int? cart;
  String? photoProfile;
  String? mobileVerifiedAt;
  num? balance;
  dynamic minWallet;
  dynamic minWalletDisabled;
  int? resturantId;
  String? resturantLat;
  String? resturantLng;
  String? resturantCity;
  String? resturantOpenAt;
  String? resturantCloseAt;
  int? resturantCityId;
  String? resturantCityname;
  String? resturantPhone;
  String? resturantName;
  String? resturantLogo;
  String? resturantBgImage;
  int? resturantAreaId;
  String? resturantAreaName;
  String? myresturantHasMenu;
  int? resturantParentId;
  String? parentHasMenu;
  String? delegateStatus;
  String? vendorStatus;
  String? createdAt;
  String? token;
  String? expirationDate;
  num? kmPrice;
  num? tax;
  num? serviceFees;
  num? minOrderPrice;
  num? delegateFees;
  List<UserAddresses>? userAddresses;
  int? notificationsCount;
  int? walletBlock;

  ProfileModel({
    this.id,
    this.name,
    this.email,
    this.accountType,
    this.appScope,
    this.isGoPartner,
    this.partnerProfessionKey,
    this.partnerProfessionNameAr,
    this.partnerProfessionNameEn,
    this.partnerWorkRadiusKm,
    this.partnerApplicationStatus,
    this.countryCode,
    this.mobile,
    this.fcmId,
    this.gender,
    this.lat,
    this.lng,
    this.countryName,
    this.cityName,
    this.address,
    this.mobileCode,
    this.areaId,
    this.areaTitle,
    this.cart,
    this.photoProfile,
    this.mobileVerifiedAt,
    this.balance,
    this.resturantId,
    this.resturantLat,
    this.resturantLng,
    this.resturantCity,
    this.resturantOpenAt,
    this.resturantCloseAt,
    this.resturantCityId,
    this.resturantCityname,
    this.resturantPhone,
    this.resturantName,
    this.resturantLogo,
    this.resturantBgImage,
    this.resturantAreaId,
    this.resturantAreaName,
    this.myresturantHasMenu,
    this.resturantParentId,
    this.parentHasMenu,
    this.delegateStatus,
    this.vendorStatus,
    this.createdAt,
    this.token,
    this.expirationDate,
    this.kmPrice,
    this.tax,
    this.serviceFees,
    this.delegateFees,
    this.userAddresses,
    this.notificationsCount,
    this.minOrderPrice,
    this.walletBlock,
  });

  ProfileModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
    accountType = json['account_type'];
    appScope = json['app_scope'];
    isGoPartner = json['is_go_partner'];
    partnerProfessionKey = json['partner_profession_key'];
    partnerProfessionNameAr = json['partner_profession_name_ar'];
    partnerProfessionNameEn = json['partner_profession_name_en'];
    partnerWorkRadiusKm = json['partner_work_radius_km'];
    partnerApplicationStatus = json['partner_application_status'];
    countryCode = json['country_code'];
    mobile = json['mobile'];
    fcmId = json['fcm_id'];
    gender = json['gender'];
    lat = json['lat'];
    lng = json['lng'];
    countryName = json['country_name'];
    cityName = json['city_name'];
    address = json['address'];
    mobileCode = json['mobile_code'];
    areaId = json['area_id'];
    areaTitle = json['area_title'];
    cart = json['cart'];
    photoProfile = json['photo_profile'];
    mobileVerifiedAt = json['mobile_verified_at'];
    balance = json['balance'];
    minWallet = json['min_wallet'];
    minWalletDisabled = json['min_wallet_disabled'];
    resturantId = json['resturant_id'];
    resturantLat = json['resturant_lat'];
    resturantLng = json['resturant_lng'];
    resturantCity = json['resturant_city'];
    resturantOpenAt = json['resturant_open_at'];
    resturantCloseAt = json['resturant_close_at'];
    resturantCityId = json['resturant_city_id'];
    resturantCityname = json['resturant_cityname'];
    resturantPhone = json['resturant_phone'];
    resturantName = json['resturant_name'];
    resturantLogo = json['resturant_logo'];
    resturantBgImage = json['resturant_bg_image'];
    resturantAreaId = json['resturant_area_id'];
    resturantAreaName = json['resturant_area_name'];
    myresturantHasMenu = json['myresturant_has_menu'];
    resturantParentId = json['resturant_parent_id'];
    parentHasMenu = json['parent_has_menu'];
    delegateStatus = json['delegate_status'];
    vendorStatus = json['vendor_status'];
    createdAt = json['created_at'];
    token = json['token'];
    expirationDate = json['expiration_date'];
    kmPrice = json['km_price'];
    tax = json['tax'];
    serviceFees = json['service_fees'];
    minOrderPrice = json['min_order_price'];
    delegateFees = json['delegate_fees'];
    if (json['user_addresses'] != null) {
      userAddresses = <UserAddresses>[];
      json['user_addresses'].forEach((v) {
        userAddresses!.add(UserAddresses.fromJson(v));
      });
    }
    notificationsCount = json['notificaions_count'];
    walletBlock = json['wallet_block'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['email'] = email;
    data['account_type'] = accountType;
    data['app_scope'] = appScope;
    data['is_go_partner'] = isGoPartner;
    data['partner_profession_key'] = partnerProfessionKey;
    data['partner_profession_name_ar'] = partnerProfessionNameAr;
    data['partner_profession_name_en'] = partnerProfessionNameEn;
    data['partner_work_radius_km'] = partnerWorkRadiusKm;
    data['partner_application_status'] = partnerApplicationStatus;
    data['country_code'] = countryCode;
    data['mobile'] = mobile;
    data['fcm_id'] = fcmId;
    data['gender'] = gender;
    data['lat'] = lat;
    data['lng'] = lng;
    data['country_name'] = countryName;
    data['city_name'] = cityName;
    data['address'] = address;
    data['mobile_code'] = mobileCode;
    data['area_id'] = areaId;
    data['area_title'] = areaTitle;
    data['cart'] = cart;
    data['photo_profile'] = photoProfile;
    data['mobile_verified_at'] = mobileVerifiedAt;
    data['balance'] = balance;
    data['min_wallet'] = minWallet;
    data['min_wallet_disabled'] = minWalletDisabled;
    data['resturant_id'] = resturantId;
    data['resturant_lat'] = resturantLat;
    data['resturant_lng'] = resturantLng;
    data['resturant_city'] = resturantCity;
    data['resturant_open_at'] = resturantOpenAt;
    data['resturant_close_at'] = resturantCloseAt;
    data['resturant_city_id'] = resturantCityId;
    data['resturant_cityname'] = resturantCityname;
    data['resturant_phone'] = resturantPhone;
    data['resturant_name'] = resturantName;
    data['resturant_logo'] = resturantLogo;
    data['resturant_bg_image'] = resturantBgImage;
    data['resturant_area_id'] = resturantAreaId;
    data['resturant_area_name'] = resturantAreaName;
    data['myresturant_has_menu'] = myresturantHasMenu;
    data['resturant_parent_id'] = resturantParentId;
    data['parent_has_menu'] = parentHasMenu;
    data['delegate_status'] = delegateStatus;
    data['vendor_status'] = vendorStatus;
    data['created_at'] = createdAt;
    data['token'] = token;
    data['expiration_date'] = expirationDate;
    data['km_price'] = kmPrice;
    data['tax'] = tax;
    data['service_fees'] = serviceFees;
    data['min_order_price'] = minOrderPrice;
    data['delegate_fees'] = delegateFees;
    if (userAddresses != null) {
      data['user_addresses'] = userAddresses!.map((v) => v.toJson()).toList();
    }
    data['notificaions_count'] = notificationsCount;
    data['wallet_block'] = walletBlock;
    return data;
  }
}

class UserAddresses {
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

  UserAddresses({
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

  UserAddresses.fromJson(Map<String, dynamic> json) {
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
