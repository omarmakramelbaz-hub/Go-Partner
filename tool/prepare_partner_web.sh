#!/usr/bin/env bash
set -euo pipefail

partner_flutter_bin="${PARTNER_FLUTTER_BIN:-flutter}"
partner_widget_test_existed=false
if [[ -e test/widget_test.dart || -L test/widget_test.dart ]]; then
  partner_widget_test_existed=true
fi

# Do not discard developer changes when this CI helper is run locally.
if ! git diff --quiet HEAD -- pubspec.yaml pubspec.lock analysis_options.yaml lib; then
  echo 'Web preparation requires committed application files and dependency policy.' >&2
  exit 1
fi

"$partner_flutter_bin" create . --platforms web --no-pub

# Flutter's template can replace the application lockfile with SDK defaults.
# Restore only the dependency/policy files changed by our scaffold invocation.
git restore --source=HEAD -- pubspec.lock analysis_options.yaml
if ! git diff --quiet HEAD -- pubspec.yaml lib ||
   [[ -n "$(git ls-files --others --exclude-standard -- lib)" ]]; then
  echo 'Platform generation changed application source or pubspec.yaml.' >&2
  exit 1
fi

# Keep every test that existed before generation, including untracked tests.
if [[ "$partner_widget_test_existed" == false ]]; then
  rm -f -- test/widget_test.dart
fi

"$partner_flutter_bin" pub get --enforce-lockfile
git restore --source=HEAD -- analysis_options.yaml
if ! git diff --quiet HEAD -- pubspec.yaml pubspec.lock lib; then
  echo 'Dependency resolution changed the committed application or lockfile.' >&2
  exit 1
fi
