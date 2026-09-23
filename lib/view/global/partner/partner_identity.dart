import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Shared identity for the signed-in GO Partner screens.
class PartnerIdentity {
  static const ink = Color(0xff171A1F);
  static const orange = Color(0xffFD7201);
  static const muted = Color(0xff7D8490);
  static const border = Color(0xffECEEF1);
}

class PartnerWordmark extends StatelessWidget {
  const PartnerWordmark({super.key, this.height = 42});
  final double height;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'GO Partner',
    image: true,
    child: SvgPicture.asset('assets/svg/go_partner_logo_light.svg', height: height, excludeFromSemantics: true),
  );
}

class PartnerTabHeader extends StatelessWidget implements PreferredSizeWidget {
  const PartnerTabHeader({
    super.key,
    required this.title,
    required this.location,
    required this.onLocationTap,
    required this.onBack,
  });
  final String title;
  final String location;
  final VoidCallback onLocationTap;
  final VoidCallback onBack;

  @override
  Size get preferredSize => const Size.fromHeight(104);

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Material(
      color: PartnerIdentity.ink,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              SizedBox(
                height: 60,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                      onPressed: onBack,
                      icon: const BackButtonIcon(),
                      color: Colors.white,
                    ),
                    Expanded(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const PartnerWordmark(height: 38),
                  ],
                ),
              ),
              InkWell(
                onTap: onLocationTap,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: PartnerIdentity.orange),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.expand_more, color: Colors.white70, size: 17),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class PartnerSurface extends StatelessWidget {
  const PartnerSurface({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: PartnerIdentity.ink,
    child: ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: ColoredBox(color: Colors.white, child: child),
    ),
  );
}
