/// The identity shipped in this application, independent of API settings.
///
/// Rebranding requires a new reviewed build. Do not add remote overrides,
/// persisted branding, or runtime identity selection here.
abstract final class PartnerAppIdentity {
  static const displayName = 'GO Partner';
  static const logoAsset = 'assets/svg/go_partner_logo.svg';
  static const lightLogoAsset = 'assets/svg/go_partner_logo_light.svg';
  static const iconAsset = 'assets/images/go_partner_app_icon.png';
  static const splashBackgroundAsset = 'assets/brand/partner_splash.webp';
  static const welcomeBackgroundAsset = 'assets/brand/partner_welcome.webp';
}
