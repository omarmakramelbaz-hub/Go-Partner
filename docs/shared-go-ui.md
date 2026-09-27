# Shared GO interface

GO Partner is the visual reference approved on 27 September 2026.
The Customer app uses the same GO vector symbol, Tajawal/Roboto typography,
orange primary controls, charcoal accents, white surfaces and rounded cards.
Application-specific content and actions remain distinct.

`lib/helpers/theme/go_design_tokens.dart` is identical in both repositories.
Keep the two copies in sync when changing the shared palette or dimensions.
Partner's existing logo, layout and wording remain the reference.

- Authentication: 420 px maximum width, 24 px side padding, 54 px primary
  buttons, a single segmented sign-in/register control and visible field labels.
- Phone numbers and passwords retain left-to-right input in both locales.
- Customer keeps guest access, social sign-in availability and all existing
  registration, recovery, request, wallet and session callbacks.
- The Customer opening uses the original Partner background and the shared GO
  mark. The HTML loader and Flutter opening use the same composition.
- No backend, payment settings, service matching or commission changes.

Customer validation: `python3 tool/verify_approved_identity.py` and
`flutter test test/go_customer_identity_test.dart test/go_customer_legal_test.dart test/go_auth_ui_test.dart`.
The auth tests capture actual Flutter screens in `build/ui-preview/` for review.
