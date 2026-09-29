import '../view/custom_widgets/popups/go_popups.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view/layout/auth/controller/auth_controller.dart';
import '../view/layout/auth/screen/login_screen.dart';
import '../view/layout/auth/bottom_sheet/change_lang_bottom_sheet.dart';
import '../view/layout/wallet/screen/wallet_screen.dart';
import '../view/layout/my_account/screen/help_screen.dart';
import 'store_catalog.dart';
import 'store_orders_screen.dart';

class StoreShell extends StatefulWidget {
  const StoreShell({super.key});
  @override
  State<StoreShell> createState() => _StoreShellState();
}

class _StoreShellState extends State<StoreShell> {
  int _index = 0;
  int _pendingOrders = 0;
  @override
  Widget build(BuildContext context) {
    final ar = context.locale.languageCode == 'ar';
    final profile = context.watch<AuthController>().profile;
    return Scaffold(
      backgroundColor: const Color(0xffF6F7F9),
      appBar: _index <= 1
          ? null
          : AppBar(
              title: Text(
                _index == 2
                    ? (ar ? 'المحفظة' : 'Wallet')
                    : (ar ? 'حساب المتجر' : 'Store account'),
              ),
            ),
      body: IndexedStack(
        index: _index,
        children: [
          StoreOrdersScreen(alertsEnabled: profile?.delegateStatus == 'active', onPendingCount: (count) { if (mounted && count != _pendingOrders) setState(() => _pendingOrders = count); }),
          const StoreCatalog(),
          const WalletScreen(embedded: true),
          ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: Color(0xffFFF0E3),
                child: Icon(
                  Icons.storefront,
                  color: Color(0xffFD7201),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                profile?.name ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(ar ? 'متجر' : 'Store', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: Text(ar ? 'المساعدة' : 'Help'),
                onTap: () => Navigator.pushNamed(context, HelpScreen.routeName),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(ar ? 'اللغة' : 'Language'),
                onTap: () => showGoModalBottomSheet(
                  context: context,
                  builder: (_) => const ChangeLangBottomSheet(),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(ar ? 'تسجيل الخروج' : 'Sign out'),
                onTap: () => context.read<AuthController>().logout(
                  onSuccess: () {
                    if (context.mounted)
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        LoginScreen.routeName,
                        (_) => false,
                      );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        indicatorColor: const Color(0xffFFF0E3),
        destinations: [
          NavigationDestination(icon: Badge(isLabelVisible: _pendingOrders > 0, label: Text('$_pendingOrders'), child: const Icon(Icons.receipt_long_outlined)), label: ar ? 'الطلبات' : 'Orders'),
          NavigationDestination(
            icon: const Icon(Icons.storefront_outlined),
            selectedIcon: const Icon(Icons.storefront),
            label: ar ? 'متجري' : 'My store',
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            label: ar ? 'المحفظة' : 'Wallet',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            label: ar ? 'حسابي' : 'Account',
          ),
        ],
      ),
    );
  }
}
