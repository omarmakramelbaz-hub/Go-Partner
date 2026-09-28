import 'package:flutter/material.dart';
import '../../custom_widgets/popups/go_popups.dart';

class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({super.key, required this.title, required this.children, this.isDark = false});
  final String title;
  final List<Widget> children;
  final bool? isDark;
  @override
  Widget build(BuildContext context) => GoSheet(title: title, dark: isDark == true,
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: children));
}
