/// Operational settings only. App identity belongs to PartnerAppIdentity.
/// Remote branding fields must not be parsed, stored, or serialized here.
class SettingModel {
  String? email;
  String? mobile;
  String? address;
  int? adminId;
  int? kmPrice;
  String? twitterLink;
  String? facebookLink;
  String? instagramLink;
  String? googleLink;
  String? privacy;
  String? terms;
  String? contactText;
  String? walletCardActivate;
  String? paymentCardActivate;
  String? minOrderPrice;
  String? adminDeviceToken;
  String? delegateVendorSmallInfo;

  SettingModel({
    this.email,
    this.mobile,
    this.address,
    this.adminId,
    this.kmPrice,
    this.twitterLink,
    this.facebookLink,
    this.instagramLink,
    this.googleLink,
    this.privacy,
    this.terms,
    this.contactText,
    this.walletCardActivate,
    this.paymentCardActivate,
    this.minOrderPrice,
    this.adminDeviceToken,
    this.delegateVendorSmallInfo,
  });

  SettingModel.fromJson(Map<String, dynamic> json) {
    email = json['email'];
    mobile = json['mobile'];
    address = json['address'];
    adminId = json['admin_id'];
    kmPrice = json['km_price'];
    twitterLink = json['twitter_link'];
    facebookLink = json['facebook_link'];
    instagramLink = json['instagram_link'];
    googleLink = json['google_link'];
    privacy = json['privacy'];
    terms = json['terms'];
    contactText = json['contact_text'];
    walletCardActivate = json['wallet_card_activate'];
    paymentCardActivate = json['payment_card_activate'];
    minOrderPrice = json['min_order_price'];
    adminDeviceToken = json['admin_device_token'];
    delegateVendorSmallInfo = json['delegate_vendor_small_info'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['email'] = email;
    data['mobile'] = mobile;
    data['address'] = address;
    data['admin_id'] = adminId;
    data['km_price'] = kmPrice;
    data['twitter_link'] = twitterLink;
    data['facebook_link'] = facebookLink;
    data['instagram_link'] = instagramLink;
    data['google_link'] = googleLink;
    data['privacy'] = privacy;
    data['terms'] = terms;
    data['contact_text'] = contactText;
    data['wallet_card_activate'] = walletCardActivate;
    data['payment_card_activate'] = paymentCardActivate;
    data['min_order_price'] = minOrderPrice;
    data['admin_device_token'] = adminDeviceToken;
    data['delegate_vendor_small_info'] = delegateVendorSmallInfo;
    return data;
  }
}
