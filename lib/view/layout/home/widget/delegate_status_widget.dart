import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/networking/notification_helper.dart';
import '../../auth/controller/auth_controller.dart';
import '../../delegate_bottom_nav_bar.dart/controller/delegate_bottom_nav_bar_controller.dart';

class DelegateStatusWidget extends StatefulWidget {
  const DelegateStatusWidget({super.key});

  @override
  State<DelegateStatusWidget> createState() => _DelegateStatusWidgetState();
}

enum DelegateStatus { active, inactive }

class _DelegateStatusWidgetState extends State<DelegateStatusWidget> {
  DelegateStatus? selectedStatus;
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = context.read<AuthController>();
    _authController.addListener(_syncStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncStatus());
  }

  void _syncStatus() {
    if (!mounted) return;
    final status = _authController.profile?.delegateStatus;
    if (status == null) return;
    final next = status == 'active'
        ? DelegateStatus.active
        : DelegateStatus.inactive;
    if (next != selectedStatus) setState(() => selectedStatus = next);
  }

  @override
  void dispose() {
    _authController.removeListener(_syncStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = selectedStatus == DelegateStatus.active;

    return ChangeNotifierProvider(
      create: (_) => DelegateBottomNavBarController(),
      child: Consumer<DelegateBottomNavBarController>(
        builder: (context, controller, _) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _changeStatus(
                active ? DelegateStatus.inactive : DelegateStatus.active,
                controller,
              ),
              borderRadius: BorderRadius.circular(24),
              child: Ink(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xffECF9F0)
                      : const Color(0xffF4F5F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: active
                        ? const Color(0xff85CEA0)
                        : const Color(0xffE6E8EC),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xff12AE69)
                            : const Color(0xffA9AFB6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            active
                                ? (context.locale.languageCode == 'ar'
                                      ? 'متصل الآن'
                                      : 'Online now')
                                : (context.locale.languageCode == 'ar'
                                      ? 'غير متصل'
                                      : 'Offline'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xff171717),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            active
                                ? AppLocaleKey.active.tr()
                                : AppLocaleKey.inactive.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xff7A7F87),
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 41,
                      height: 24,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xff16B66D)
                            : const Color(0xffD9DDE2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        alignment: active
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _changeStatus(
    DelegateStatus status,
    DelegateBottomNavBarController controller,
  ) {
    setState(() => selectedStatus = status);
    SoundNotification.instance.stopSound();
    controller.changeStatusOnline(
      connected: status == DelegateStatus.active ? 'active' : 'inactive',
      onSuccess: () => context.read<AuthController>().getProfile(),
    );
  }
}
