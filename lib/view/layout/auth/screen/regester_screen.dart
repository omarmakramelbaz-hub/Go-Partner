import 'package:flutter/material.dart';

import 'partner_application_screen.dart';

class RegisterAsDeliveryScreenArgs {
  final VoidCallback onSuccess;

  RegisterAsDeliveryScreenArgs({required this.onSuccess});
}

/// Backward-compatible route name for older deep links.
///
/// Direct partner account creation is intentionally disabled. Every new
/// courier/professional must submit a GO partner application and receive
/// approval before an account can be activated.
class RegisterAsDeliveryScreen extends StatelessWidget {
  static const String routeName = 'RegisterAsDeliveryScreen';

  final RegisterAsDeliveryScreenArgs args;

  const RegisterAsDeliveryScreen({
    super.key,
    required this.args,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) args.onSuccess.call();
      },
      child: const PartnerApplicationScreen(),
    );
  }
}
