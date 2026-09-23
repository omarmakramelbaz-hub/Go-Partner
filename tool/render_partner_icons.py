"""Generate platform icon sizes from the GO Partner master (requires Pillow)."""
from pathlib import Path
from PIL import Image
root = Path(__file__).resolve().parent.parent
icon = Image.open(root/'assets/images/go_partner_app_icon.png').convert('RGB')
# Retain each platform's existing dimensions and filenames.
paths = list((root/'android/app/src/main/res').glob('mipmap-*/ic_launcher.png'))
paths += list((root/'ios/Runner/Assets.xcassets/AppIcon.appiconset').glob('*.png'))
paths += list((root/'web/icons').glob('*.png')) + [root/'web/favicon.png']
for path in paths:
    size = Image.open(path).size
    icon.resize(size, Image.Resampling.LANCZOS).save(path)
