"""Export generated brand artwork into platform-required launcher/store sizes.
Requires ImageMagick. Does not delete files.
"""
from pathlib import Path
import json, subprocess
ROOT=Path(__file__).resolve().parents[1]
MASTER=ROOT/'assets/branding/app-icon-master.png'
def export(path,size):
    path=ROOT/path; path.parent.mkdir(parents=True,exist_ok=True)
    subprocess.run(['convert',str(MASTER),'-resize',f'{size}x{size}!','-background','#7755DC','-alpha','remove','-alpha','off',str(path)],check=True)
export(Path('store/android/app-icon-512.png'),512)
export(Path('store/ios/app-icon-1024.png'),1024)
for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    export(Path(f'android/app/src/main/res/mipmap-{density}/ic_launcher.png'),size)
    export(Path(f'android/app/src/main/res/mipmap-{density}/ic_launcher_round.png'),size)
    # Full artwork scaled into adaptive icon safe zone on the same purple field.
    dest=ROOT/f'android/app/src/main/res/mipmap-{density}/ic_launcher_foreground.png'
    subprocess.run(['convert',str(MASTER),'-resize',f'{size}x{size}!', '-gravity','center','-background','#7755DC','-extent',f'{round(size*2.25)}x{round(size*2.25)}',str(dest)],check=True)
contents=ROOT/'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json'
for item in json.loads(contents.read_text())['images']:
    size=float(item['size'].split('x')[0])*float(item['scale'].rstrip('x'))
    export(Path('ios/Runner/Assets.xcassets/AppIcon.appiconset')/item['filename'],round(size))
for name,size in [('Icon-192.png',192),('Icon-512.png',512),('Icon-maskable-192.png',192),('Icon-maskable-512.png',512)]:
    export(Path('web/icons')/name,size)
export(Path('web/favicon.png'),32)
print('Exported store, Android, iOS and web icon sets.')
