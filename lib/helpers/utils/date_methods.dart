import '../../view/custom_widgets/popups/go_popups.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../extension/context_extension.dart';
import '../extension/date_time_extension.dart';
import '../hive/hive_methods.dart';
import '../routes/app_routers_import.dart';
import '../theme/app_colors.dart';

class DateMethods {
  static String formatToDate(String? date) {
    DateTime? dateTime = DateTime.tryParse(date.toString());
    return dateTime != null ? DateFormat('yyyy-MM-dd', 'en').format(dateTime) : '';
  }

  static String formatOrderDate(String? date) {
    DateTime? dateTime = DateTime.tryParse(date.toString());
    return dateTime != null ? DateFormat('hh:mm  yyyy-MM-dd', 'en').format(dateTime) : '';
  }

  static String formatDateToArabic(String createdAt) {
    // Parse the original string into a DateTime object
    DateTime date = DateTime.parse(createdAt);

    // or Locale('ar') for general Arabic

    // Format the date to "EEEE, d MMMM" (e.g., "Saturday, 17 August")
    String formattedDate = DateFormat('EEEE, d MMMM', HiveMethods.getLang()).format(date);

    return formattedDate;
  }

  static String formatToFullData(String? date) {
    DateTime? dateTime = DateTime.tryParse(date.toString());
    return dateTime != null
        ? DateFormat(
            'dd MMMM yyyy - hh:mm a',
            AppRouters.navigatorKey.currentContext!.locale.languageCode,
          ).format(dateTime)
        : '';
  }

  static String formatToTime(String? date) {
    DateTime? dateTime = DateTime.tryParse(date.toString());
    return dateTime != null
        ? DateFormat('hh:mm a', AppRouters.navigatorKey.currentContext!.locale.languageCode).format(dateTime)
        : '';
  }

  static String formatCustomToTime(String date) {
    final parsedDate = DateTime.parse(date);
    return DateFormat('HH:mm').format(parsedDate);
  }

  static String formatTime(String? time) {
    Map<int, String>? s = time?.split(':').asMap();

    int hours = s?.containsKey(0) == true ? int.parse(s![0]!) : 00;
    int minutes = s?.containsKey(1) == true ? int.parse(s![1]!) : 00;

    DateTime? dateTime = s != null ? DateTime(0000, 00, 00, hours, minutes) : null;
    return dateTime != null
        ? DateFormat('hh:mm a', AppRouters.navigatorKey.currentContext!.locale.languageCode).format(dateTime)
        : '';
  }

  static bool timeBetween(String? start, String? end) {
    Map<int, String>? s = start?.split(':').asMap();

    int hoursS = s?.containsKey(0) == true ? int.parse(s![0]!) : 00;
    int minutesS = s?.containsKey(1) == true ? int.parse(s![1]!) : 00;

    Map<int, String>? e = end?.split(':').asMap();

    int hoursE = e?.containsKey(0) == true ? int.parse(e![0]!) : 00;
    int minutesE = e?.containsKey(1) == true ? int.parse(e![1]!) : 00;

    DateTime? startTime = s != null ? DateTime(0000, 00, 00, hoursS, minutesS) : null;
    DateTime? endTime = e != null ? DateTime(0000, 00, 00, hoursE, minutesE) : null;
    DateTime? nowTime = e != null ? DateTime(0000, 00, 00, TimeOfDay.now().hour, TimeOfDay.now().minute) : null;

    if (startTime != null && endTime != null) {
      if (nowTime.isBetween(startTime, endTime)!) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  static String timeAgo(String? date, BuildContext context) {
    DateTime? dateTime = DateTime.tryParse(date.toString());

    return dateTime != null ? timeago.format(dateTime, locale: context.locale.languageCode) : '';
  }

  static int daysInMonth(final int monthNum, final int year) {
    List<int> monthLength = List.filled(12, 0);
    monthLength[0] = 31;
    monthLength[2] = 31;
    monthLength[4] = 31;
    monthLength[6] = 31;
    monthLength[7] = 31;
    monthLength[9] = 31;
    monthLength[11] = 31;
    monthLength[3] = 30;
    monthLength[8] = 30;
    monthLength[5] = 30;
    monthLength[10] = 30;

    if (leapYear(year) == true) {
      monthLength[1] = 29;
    } else {
      monthLength[1] = 28;
    }

    return monthLength[monthNum - 1];
  }

  static bool leapYear(int year) {
    bool leapYear = false;
    bool leap = ((year % 100 == 0) && (year % 400 != 0));
    if (leap == true) {
      leapYear = false;
    } else if (year % 4 == 0) {
      leapYear = true;
    }

    return leapYear;
  }

  static String monthName(int month) {
    DateTime dateTime = DateTime(0, month);
    return DateFormat('MMMM', AppRouters.navigatorKey.currentContext!.locale.languageCode).format(dateTime);
  }

  static String? weekdayName(int? weekday, BuildContext context) {
    const Map<int, String> weekdayNameEn = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };

    const Map<int, String> weekdayNameAr = {
      1: 'الأثنين',
      2: 'الثلاثاء',
      3: 'الأربعاء',
      4: 'الخميس',
      5: 'الجمعه',
      6: 'السبت',
      7: 'الأحد',
    };
    return weekday != null ? context.apiTr(ar: weekdayNameAr[weekday] ?? '', en: weekdayNameEn[weekday] ?? '') : null;
  }

  static Future<void> pickDate(
    BuildContext context, {
    required DateTime initialDate,
    required void Function(DateTime) onSuccess,
    DateTime? firstDate,
    DateTime? lastDate,
    Color? mainColor,
    Color backgroundColor = Colors.white,
    Color textColor = Colors.black,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime.now().subtract(const Duration(days: 365 * 10)),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365 * 30)),
      builder: (context, child) {
        return Theme(
          data: GoPopupTheme.data(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: mainColor ?? AppColor.mainAppColor(context),
              onPrimary: backgroundColor,
              surface: backgroundColor,
              onSurface: textColor,
            ),
            dialogBackgroundColor: backgroundColor,
            textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: textColor)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onSuccess.call(picked);
    }
  }

  static Future<void> pickTime(
    BuildContext context, {
    required DateTime initialDate,
    required void Function(DateTime) onSuccess,
    Color? mainColor,
    Color backgroundColor = Colors.white,
    Color textColor = Colors.black,
  }) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialDate.hour, minute: initialDate.minute),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: Theme(
            data: GoPopupTheme.data(context).copyWith(
              colorScheme: ColorScheme.dark(
                primary: mainColor ?? AppColor.mainAppColor(context),
                onPrimary: backgroundColor,
                surface: backgroundColor,
                onSurface: textColor,
              ),
              dialogBackgroundColor: backgroundColor,
              textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: textColor)),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      DateTime time = DateTime(0000, 00, 00, picked.hour, picked.minute);
      onSuccess.call(time);
    }
  }
}
