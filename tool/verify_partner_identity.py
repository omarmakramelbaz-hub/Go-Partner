"""Check that the packaged identity agrees with native app metadata."""

from pathlib import Path
import plistlib
import re
import xml.etree.ElementTree as ET


def main():
    root = Path(__file__).resolve().parents[1]
    identity = (root / "lib/helpers/identity/partner_app_identity.dart").read_text()
    constants = dict(re.findall(r"static const (\w+) = '([^']+)';", identity))
    name = constants["displayName"]
    errors = []

    for key, value in constants.items():
        if key.endswith("Asset") and (
            not value.startswith("assets/") or not (root / value).is_file()
        ):
            errors.append(f"{key} must point to a bundled asset: {value}")

    with (root / "ios/Runner/Info.plist").open("rb") as stream:
        plist = plistlib.load(stream)
    for key in ("CFBundleDisplayName", "CFBundleName"):
        if plist.get(key) != name:
            errors.append(f"iOS {key} must match {name}")

    project = (root / "ios/Runner.xcodeproj/project.pbxproj").read_text()
    display_names = re.findall(r'INFOPLIST_KEY_CFBundleDisplayName = "([^"]+)";', project)
    if not display_names or any(value != name for value in display_names):
        errors.append("All Xcode configurations must use the packaged display name")

    application = ET.parse(root / "android/app/src/main/AndroidManifest.xml").getroot().find("application")
    label = application.get("{http://schemas.android.com/apk/res/android}label")
    if label != name:
        errors.append(f"Android application label must match {name}")

    if errors:
        raise SystemExit("\n".join(errors))
    print(f"Packaged identity verified: {name}; local assets and native names match.")


if __name__ == "__main__":
    main()
