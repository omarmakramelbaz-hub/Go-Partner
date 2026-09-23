part of 'app_routers_import.dart';

class AppRouters {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    dynamic args;
    if (settings.arguments != null) args = settings.arguments;
    switch (settings.name) {
      case ZoomImageScreen.routeName:
        return MaterialPageRoute(builder: (_) => ZoomImageScreen(args: args));
      case SplashScreen.routeName:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case LoginScreen.routeName:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case PartnerOnboardingScreen.routeName:
        return MaterialPageRoute(builder: (_) => const PartnerOnboardingScreen());

      case ForgetPasswordScreen.routeName:
        return MaterialPageRoute(builder: (_) => const ForgetPasswordScreen());
      case PasswordChangedSuccessfullyScreen.routeName:
        return MaterialPageRoute(builder: (_) => const PasswordChangedSuccessfullyScreen());

      case HelpScreen.routeName:
        return MaterialPageRoute(builder: (_) => const HelpScreen());
      case PrivacyPolicyScreen.routeName:
        return MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen());
      case TermsAndConditionsScreen.routeName:
        return MaterialPageRoute(builder: (_) => const TermsAndConditionsScreen());
      case ContactUsScreen.routeName:
        return MaterialPageRoute(builder: (_) => const ContactUsScreen());
      case WalletScreen.routeName:
        return MaterialPageRoute(builder: (_) => const WalletScreen());

      // !======================Delegate======================
      case DelegateBottomNavBarScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => MultiProvider(
            providers: [ChangeNotifierProvider(create: (_) => NotificationsDelegateController())],
            child: const DelegateBottomNavBarScreen(),
          ),
        );

      case PersonalInformationDelegateScreen.routeName:
        return MaterialPageRoute(builder: (_) => const PersonalInformationDelegateScreen());
      case ChangePasswordDelegateScreen.routeName:
        return MaterialPageRoute(builder: (_) => const ChangePasswordDelegateScreen());
      case CurrentOrdersDelegateScreen.routeName:
        return MaterialPageRoute(builder: (_) => CurrentOrdersDelegateScreen(args: args));

      case OrderDetailsDelegateScreen.routeName:
        return MaterialPageRoute(builder: (_) => OrderDetailsDelegateScreen(args: args));
      case DelegateLocationScreen.routeName:
        return MaterialPageRoute(builder: (_) => const DelegateLocationScreen());

      case DelegateReportsScreen.routeName:
        return MaterialPageRoute(builder: (_) => const DelegateReportsScreen());
      case ChatScreen.routeName:
        return MaterialPageRoute(builder: (_) => ChatScreen(args: args));
      case DeliveryLocationScreen.routeName:
        return MaterialPageRoute(builder: (_) => DeliveryLocationScreen(args: args));
      case CustomPaymentWebViewScreen.routeName:
        return MaterialPageRoute(builder: (_) => CustomPaymentWebViewScreen(args: args));
      case AdminChatScreen.routeName:
        return MaterialPageRoute(builder: (_) => AdminChatScreen(args: args));
      case RegisterAsDeliveryScreen.routeName:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (context) => DelegateAccountController(),
            child: RegisterAsDeliveryScreen(args: args),
          ),
        );
      case ContractDeliveryScreen.routeName:
        return MaterialPageRoute(builder: (_) => ContractDeliveryScreen(args: args));
      default:
        return MaterialPageRoute(builder: (_) => const DelegateBottomNavBarScreen());
    }
  }
}
