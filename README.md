# GO Partner

GO Partner is the Flutter app for couriers, approved professional service
partners, and store partners in the GO ecosystem. The release version is defined
in `pubspec.yaml`; CI currently uses Flutter 3.47.0.

## Code layout

| Path | Responsibility |
| --- | --- |
| `lib/main.dart`, `lib/app.dart` | Local startup, deferred native services, providers, and application shell. |
| `lib/helpers/` | Shared networking, Hive state, navigation, localization, themes, notifications, and Pusher integration. |
| `lib/view/layout/` | Authentication, courier orders, maps, wallet, and account screens with their controllers and models. |
| `lib/view/custom_widgets/`, `lib/view/global/` | Reusable UI, chat, partner identity, and map support. |
| `lib/go_services/` | Professional service requests, quotations, and wallet notices. |
| `lib/go_stores/`, `lib/go_store_signup/` | Store enrollment, catalog editing, and order management. |
| `i18n/`, `assets/` | Arabic/English translations, fonts, branding, and other packaged assets. |
| `test/`, `tool/` | Unit/widget regressions, app identity checks, and web packaging/bootstrap checks. |

The API base URL is defined in `lib/helpers/networking/urls.dart`. Partner
requests use the `go_partner` scope. Wallet balances, commissions, order
assignments, and fulfillment permissions are determined by the backend.

Startup initializes local Hive data and localization before launching the UI.
Native Firebase and messaging initialization runs after `runApp`, with errors
handled separately from local startup. Native HTTPS uses platform certificate
validation.

Job details read current job data and capabilities concurrently on every
refresh. Successful partial job data remains visible with actions disabled
until both reads succeed. Responses from a previous login session are discarded.

## Development checks

Run these commands from the repository root with the CI Flutter version:

```sh
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
GO_STORE_SCREENSHOTS=test-output/go-stores flutter test
python3 tool/verify_partner_identity.py
python3 -m unittest discover -s tool -p test_package_partner_web.py
python3 -m unittest discover -s tool -p test_prepare_partner_web.py
node --test tool/test_web_bootstrap.cjs
```

The analyzer flags match CI and still report warnings and informational issues;
new findings should be reviewed. The focused network regression checks can be
run with `flutter test test/networking_safety_test.dart test/service_refresh_test.dart`.

For interactive development, select a configured device with `flutter devices`
and then use `flutter run -d <device-id>`. Android and iOS release build setup is
documented by `.github/workflows/android-apk.yml` and `ios-build.yml`, including
their platform toolchains and compatibility steps. Web packaging and preview
checks are defined in `partner-checks.yml` and `web-build.yml`.

Those workflows use `bash tool/prepare_partner_web.sh` from a committed checkout
to generate web support, restore scaffolded lockfile changes, and enforce the
committed dependencies once. Subsequent analyze, test, and build commands use
`--no-pub`. Existing widget tests are preserved; only a newly generated counter
test is removed. Application source or manifest changes fail preparation.

## Test boundaries

Flutter unit and widget tests run on the host and use fake platform services or
API adapters where supplied. They do not certify device location permissions,
background tracking, real push delivery, payment WebViews, or native release
signing. Validate those flows on Android/iOS devices with the corresponding
service configuration before a release. Keep formatting changes scoped to the
files being edited so that behavioral changes remain easy to review.
