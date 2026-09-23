import 'package:flutter/material.dart';

import '../../custom_widgets/custom_image/custom_image.dart';

class CustomElevatedButton extends StatelessWidget {
  const CustomElevatedButton({super.key, required this.onPressed, required this.imagePath, this.size});
  final VoidCallback onPressed;
  final String imagePath;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final resolvedSize = size ?? 38;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(resolvedSize * .36),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(resolvedSize * .36),
          child: Container(
            height: resolvedSize,
            width: resolvedSize,
            padding: EdgeInsets.all(resolvedSize * .24),
            decoration: BoxDecoration(
              color: const Color(0xffFFF0E3),
              borderRadius: BorderRadius.circular(resolvedSize * .36),
              border: Border.all(color: const Color(0xffFFE0C5)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF171A1F).withOpacity(.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CustomImage(
              path: imagePath,
              type: ImageType.svg,
              color: const Color(0xffFD7201),
            ),
          ),
        ),
      ),
    );
  }
}
