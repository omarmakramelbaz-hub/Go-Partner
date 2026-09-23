import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../helpers/identity/partner_app_identity.dart';

class PartnerAuthScaffold extends StatelessWidget {
  const PartnerAuthScaffold({
    super.key,
    required this.title,
    required this.description,
    required this.children,
  });
  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xff171a1f),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: SvgPicture.asset(
                      PartnerAppIdentity.logoAsset,
                      width: 170,
                      height: 130,
                    ),
                  ),
                  const Text(
                    'معًا نصنع الفرص',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: Color(0xff171a1f),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xff737b86),
                      height: 1.6,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class PartnerAuthButton extends StatelessWidget {
  const PartnerAuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 54,
    child: FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xfffd7201),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xfffd7201),
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
    ),
  );
}

class PartnerAuthError extends StatelessWidget {
  const PartnerAuthError(this.message, {super.key});
  final String? message;
  @override
  Widget build(BuildContext context) => message == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Semantics(
            liveRegion: true,
            child: Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xffb42318), height: 1.5),
            ),
          ),
        );
}
