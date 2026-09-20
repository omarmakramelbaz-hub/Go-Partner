import 'package:flutter/material.dart';

import 'partner_onboarding_screen.dart';

class RegisterAsDeliveryScreenArgs {
  final VoidCallback onSuccess;

  RegisterAsDeliveryScreenArgs({required this.onSuccess});
}

/// Compatibility route kept for existing navigation. The old courier-only
/// registration form is replaced by the unified GO professional partner flow.
class RegisterAsDeliveryScreen extends StatelessWidget {
  static const String routeName = 'RegisterAsDeliveryScreen';

  final RegisterAsDeliveryScreenArgs args;

  const RegisterAsDeliveryScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return PartnerOnboardingScreen(onFinished: args.onSuccess);
  }
}
