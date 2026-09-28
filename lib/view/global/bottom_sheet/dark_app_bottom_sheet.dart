// import 'package:flutter/material.dart';

// import '../../../helpers/theme/app_colors.dart';
// import '../../../helpers/theme/app_text_style.dart';

// class DarkAppBottomSheet extends StatelessWidget {
//   const DarkAppBottomSheet({
//     super.key,
//     required this.title,
//     required this.children,
//     this.isDark = false,
//     this.showBorder = false,
//   });
//   final String title;
//   final List<Widget> children;
//   final bool? isDark;
//   final bool? showBorder;
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(top: 20),
//       decoration: BoxDecoration(
//         color: isDark == true ? AppColor.blackColor(context) : AppColor.whiteColor(context),
//         borderRadius: const BorderRadius.only(topLeft: Radius.circular(36), topRight: Radius.circular(36)),
//         border: Border.all(color: showBorder == true ? AppColor.lightDarkColor(context) : AppColor.blackColor(context)),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 20),
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               const SizedBox(height: 15),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(title, style: AppTextStyle.text16MS(context).copyWith(color: AppColor.whiteColor(context))),
//                 ],
//               ),
//               const SizedBox(height: 15),
//               const SizedBox(height: 15),
//               ...children,
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
