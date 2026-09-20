import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../../../helpers/networking/api_helper.dart';
import '../../../../../../helpers/utils/navigator_methods.dart';
import '../../../helpers/hive/hive_methods.dart';
import '../../../helpers/pusher_service/pusher_controller.dart';
import '../auth/controller/auth_controller.dart';
import '../auth/screen/login_screen.dart';
import '../delegate_bottom_nav_bar.dart/screen/delegate_bottom_nav_bar_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String routeName = 'SplashScreen';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;
  final DateTime _openingStartedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initial();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(child: _GoPartnerOpening()),
    );
  }

  Future<void> _goLogin() async {
    await _waitForOpening();
    if (!mounted || _navigated) return;
    _navigated = true;
    NavigatorMethods.pushNamedAndRemoveUntil(context, LoginScreen.routeName);
  }

  Future<void> _goHome() async {
    await _waitForOpening();
    if (!mounted || _navigated) return;
    _navigated = true;
    NavigatorMethods.pushNamedAndRemoveUntil(
      context,
      DelegateBottomNavBarScreen.routeName,
    );
  }

  Future<void> _waitForOpening() async {
    final elapsed = DateTime.now().difference(_openingStartedAt).inMilliseconds;
    final remainingMs = 3000 - elapsed;
    if (remainingMs > 0) {
      await Future.delayed(Duration(milliseconds: remainingMs));
    }
  }

  void _initial() {
    if (HiveMethods.getToken() != null) {
      context.read<AuthController>().initialProfile();
      _getData();
    } else {
      _goLogin();
    }
  }

  Future<void> _getData() async {
    final authController = context.read<AuthController>();

    try {
      await authController
          .getProfile(
            onHaveId: (id, token) {
              if (!kIsWeb) {
                context.read<PusherController>().initPusher(
                  channelName: 'private-user.$id',
                  userId: id,
                  token: token,
                );
              }
            },
            onSuccess: () {
              _goHome();
            },
            onUnauthenticated: () {
              HiveMethods.deleteToken();
              _goLogin();
            },
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      HiveMethods.deleteToken();
      _goLogin();
      return;
    } catch (_) {
      HiveMethods.deleteToken();
      _goLogin();
      return;
    }

    final state = authController.profileResponse.state;
    if (state != ResponseState.complete && state != ResponseState.loading) {
      HiveMethods.deleteToken();
      _goLogin();
    }
  }
}

class _GoPartnerOpening extends StatelessWidget {
  const _GoPartnerOpening();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final logoWidth = (constraints.maxWidth * .72).clamp(240.0, 360.0);

        return ColoredBox(
          color: Colors.white,
          child: Center(
            child: SvgPicture.asset(
              'assets/svg/go_partner_logo.svg',
              width: logoWidth,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }
}
