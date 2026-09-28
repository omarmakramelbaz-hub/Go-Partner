import '../popups/go_popups.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../helpers/images/app_images.dart';
import '../../../helpers/locale/app_locale_key.dart';
import '../../../helpers/theme/app_colors.dart';
import '../../../helpers/utils/general_const.dart';

class ChooseGalleryOrCameraBottomSheet extends StatelessWidget {
  final void Function()? onCamera;
  final void Function()? onGallery;
  const ChooseGalleryOrCameraBottomSheet({super.key, this.onCamera, this.onGallery});

  @override
  Widget build(BuildContext context) => GoSheet(
    title: 'popupChoosePhoto'.tr(), icon: Icons.add_photo_alternate_outlined,
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      OutlinedButton.icon(onPressed: onCamera, icon: const Icon(Icons.photo_camera_outlined), label: Text('camera'.tr())),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: onGallery, icon: const Icon(Icons.photo_library_outlined), label: Text('gallery'.tr())),
    ]),
  );
}
