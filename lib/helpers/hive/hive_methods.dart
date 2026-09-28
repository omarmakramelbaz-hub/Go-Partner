import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../theme/theme_enum.dart';

class HiveMethods {
  static final _box = Hive.box('app');

  static String getLang() {
    return _box.get('lang', defaultValue: 'ar');
  }

  static Future<void> updateLang(Locale locale) async {
    await _box.put('lang', locale.languageCode);
  }

  static String? getToken() {
    return _box.get('token');
  }

  static Future<void> updateToken(String token) async {
    await _box.put('token', token);
  }

  // static String? hasDelegateOrVendor() {
  //   return _box.get('hasDelegateOrVendor');
  // }

  // static void updateDelegateOrVendor(String hasDelegateOrVendor) {
  //   _box.put('hasDelegateOrVendor', hasDelegateOrVendor);
  // }

  static void deleteToken() {
    _box.delete('token');
  }

  static bool isFirstTime() {
    return _box.get('isFirstTime', defaultValue: true);
  }

  static void updateFirstTime() {
    _box.put('isFirstTime', false);
  }

  static ThemeEnum getTheme() {
    return _box.get('theme', defaultValue: ThemeEnum.light);
  }

  static void updateThem(ThemeEnum theme) {
    _box.put('theme', theme);
  }

  static double? getLat() {
    return _box.get('lat');
  }

  static void updateLat(double lat) {
    _box.put('lat', lat);
  }

  static double? getLan() {
    return _box.get('lan');
  }

  static void updateLan(double lan) {
    _box.put('lan', lan);
  }

  static bool isFirstTimeInProducts() {
    return _box.get('isFirstTime', defaultValue: true);
  }

  static void updateFirstTimeInProducts() {
    _box.put('isFirstTime', false);
  }

  static void delegateAddress(String address) {
    _box.put('address', address);
  }

  static String? getDelegateAddress() {
    return _box.get('address');
  }

  static bool? isFreeDelivery() {
    return _box.get('isFreeDelivery');
  }

  static void setIsFreeDelivery(bool isFreeDelivery) {
    _box.put('isFreeDelivery', isFreeDelivery);
  }

  static void deleteIsFreeDelivery() {
    _box.delete('isFreeDelivery');
  }
}
