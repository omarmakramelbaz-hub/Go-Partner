# GO Partner: App Review 2.3.1(a)

Apple's message for iOS 1.0.23 identifies “remote identity configuration
functionality.” The message does not identify a source file or execution path.

## Findings and changes

- The historical 1.0.23 source and current settings model both accepted and
  serialized server-provided `logo` and `favicon` fields. No current UI consumer
  of those settings fields was found. These fields have now been removed.
- `PartnerAppIdentity` defines the packaged display name and bundled logo,
  launcher/fallback icon, splash, and welcome assets as compile-time constants.
  App title, authentication screens, onboarding, splash, and signed-in wordmark
  use these constants. It has no remote loader or runtime override.
- Operational settings (support contacts, terms, privacy, and payment method
  availability) remain supported. Customer/provider photos and order data are
  content, not sources for app identity.
- Regression tests prove that legacy or malformed branding fields are ignored,
  operational settings survive, and the wordmarks use bundled asset loaders.
  CI also checks that native display names agree with the packaged identity.

## Before the next Apple submission

Finish the ongoing GO Partner work and test the signed iOS build. Verify App
Store Connect's name, description, screenshots, and review notes against the
actual new build, including courier and professional-service workflows and a
usable reviewer account. Describe the removal of the legacy branding fields
accurately; do not claim that Apple has accepted this fix or that an unobserved
runtime identity switch was reproduced.

This change does not upload a build to TestFlight or submit it for App Review.
The repository's iOS workflow produces an unsigned build artifact only.
