import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_partner/helpers/identity/partner_app_identity.dart';
import 'package:go_partner/helpers/images/app_images.dart';
import 'package:go_partner/view/global/partner/partner_identity.dart';
import 'package:go_partner/view/layout/auth/widget/partner_auth_scaffold.dart';
import 'package:go_partner/view/layout/my_account/model/setting_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'legacy remote branding is discarded while operational settings survive',
    () {
      final operational = <String, dynamic>{
        'email': 'support@example.test',
        'mobile': '01000000000',
        'admin_id': 12,
        'km_price': 50,
        'privacy': 'Privacy policy',
        'terms': 'Partner terms',
        'contact_text': 'Contact support',
        'wallet_card_activate': 'true',
        'payment_card_activate': 'false',
      };
      final remoteBranding = <String, dynamic>{
        'logo': 'https://example.test/other-app.svg',
        'favicon': 'https://example.test/other-icon.png',
        'app_name': 'Different App',
        'display_name': 'Different App',
        'app_icon': 'https://example.test/icon.png',
        'splash_image': 'https://example.test/splash.png',
        'identity': {
          'name': 'Different App',
          'logo': 'https://example.test/logo',
        },
        'branding': {'primary_color': '#ffffff'},
      };

      final clean = SettingModel.fromJson(operational).toJson();
      final withBranding = SettingModel.fromJson({
        ...operational,
        ...remoteBranding,
      }).toJson();
      expect(withBranding, clean);
      for (final key in remoteBranding.keys) {
        expect(withBranding.containsKey(key), isFalse, reason: key);
      }
      for (final entry in operational.entries) {
        expect(withBranding[entry.key], entry.value, reason: entry.key);
      }

      // Malformed branding must not prevent valid settings from loading either.
      expect(
        SettingModel.fromJson({...operational, 'logo': 123, 'favicon': false})
            .toJson(),
        clean,
      );
      expect(PartnerAppIdentity.displayName, 'GO Partner');
    },
  );

  test(
    'all identity assets are bundled and fallback icons use GO Partner',
    () async {
      for (final asset in [
        PartnerAppIdentity.logoAsset,
        PartnerAppIdentity.lightLogoAsset,
        PartnerAppIdentity.iconAsset,
        PartnerAppIdentity.splashBackgroundAsset,
        PartnerAppIdentity.welcomeBackgroundAsset,
      ]) {
        expect(asset.startsWith('assets/'), isTrue);
        expect((await rootBundle.load(asset)).lengthInBytes, greaterThan(0));
      }
      expect(AppImages.appIcon, PartnerAppIdentity.iconAsset);
      expect(AppImages.lastSplash, PartnerAppIdentity.iconAsset);
      expect(AppImages.delegateFinalLogoImage, PartnerAppIdentity.iconAsset);
    },
  );

  testWidgets('signed-in header and authentication use local logo loaders', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PartnerWordmark())),
      );
      await tester.pumpAndSettle();
      var logo = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(logo.bytesLoader, isA<SvgAssetLoader>());
      expect(
        (logo.bytesLoader as SvgAssetLoader).assetName,
        PartnerAppIdentity.lightLogoAsset,
      );
      expect(find.bySemanticsLabel('GO Partner'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: PartnerAuthScaffold(
            title: 'Partner',
            description: 'Sign in',
            children: [],
          ),
        ),
      );
      await tester.pumpAndSettle();
      logo = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(logo.bytesLoader, isA<SvgAssetLoader>());
      expect(
        (logo.bytesLoader as SvgAssetLoader).assetName,
        PartnerAppIdentity.logoAsset,
      );
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}
