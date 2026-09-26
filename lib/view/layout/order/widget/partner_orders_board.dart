import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../go_services/partner_service_board.dart';
import '../../auth/controller/auth_controller.dart';
import '../controller/partner_orders_controller.dart';
import 'legacy_partner_orders_board.dart' as legacy;

/// The public board contract is unchanged. Couriers keep the original UI;
/// eligible professional accounts use marketplace jobs in this SAME section.
class PartnerOrdersBoard extends StatelessWidget {
  const PartnerOrdersBoard({super.key, this.onViewAll, this.section});
  final VoidCallback? onViewAll;
  final int? section;
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PartnerOrdersController>();
    if (!controller.isProfessional) return legacy.PartnerOrdersBoard(onViewAll: onViewAll, section: section);
    return PartnerServiceBoard(ar: context.locale.languageCode == 'ar',
      scope: section == 0 ? 'new' : section == 1 ? 'current' : section == 2 ? 'history' : 'open',
      onViewAll: onViewAll,
      onChanged: () { context.read<AuthController>().getProfile(); controller.refresh(); },
      legacyBuilder: (_) => legacy.PartnerOrdersBoard(onViewAll: onViewAll, section: section));
  }
}
