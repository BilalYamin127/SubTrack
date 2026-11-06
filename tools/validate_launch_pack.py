"""Validate store copy, image specifications, referenced icons and policy assets.
Does not delete, clear or upload anything. Writes only asset-manifest.json.
"""
from pathlib import Path
import hashlib,json,struct,subprocess,xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]
checks=[]
def require(condition,message):
    if not condition: raise AssertionError(message)
    checks.append(message)
def text_limit(path,limit):
    value=(ROOT/path).read_text().strip()
    require(0<len(value)<=limit,f'{path}: {len(value)}/{limit} characters')
for p,limit in [('store/android/en-US/title.txt',30),('store/android/en-US/short-description.txt',80),('store/android/en-US/full-description.txt',4000),('store/android/en-US/release-notes.txt',500),('store/ios/en-US/name.txt',30),('store/ios/en-US/subtitle.txt',30),('store/ios/en-US/promotional-text.txt',170),('store/ios/en-US/description.txt',4000),('store/ios/en-US/keywords.txt',100),('store/ios/en-US/whats-new.txt',4000)]:text_limit(Path(p),limit)
assets=[]
def png(path,expected=None,opaque=False):
    data=path.read_bytes();require(data[:8]==b'\x89PNG\r\n\x1a\n',f'{path.relative_to(ROOT)}: PNG format')
    width,height=struct.unpack('>II',data[16:24])
    if expected:require((width,height)==expected,f'{path.relative_to(ROOT)}: {width}x{height}')
    if opaque:
        status=subprocess.check_output(['identify','-format','%[opaque]',str(path)],text=True).strip().lower()
        require(status=='true',f'{path.relative_to(ROOT)}: opaque')
    assets.append({'path':str(path.relative_to(ROOT)),'width':width,'height':height,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()})
png(ROOT/'store/android/app-icon-512.png',(512,512),True)
png(ROOT/'store/ios/app-icon-1024.png',(1024,1024),True)
png(ROOT/'store/android/feature-graphic-1024x500.png',(1024,500),True)
for platform,dimensions in [('android',(1080,1920)),('ios',(1320,2868))]:
    shots=sorted((ROOT/f'store/{platform}/en-US/screenshots').glob('*.png'))
    require(len(shots)==8,f'{platform}: exactly 8 screenshots')
    for shot in shots:png(shot,dimensions,True)
for density,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:png(ROOT/f'android/app/src/main/res/mipmap-{density}/ic_launcher.png',(size,size),True)
contents=json.loads((ROOT/'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json').read_text())
seen=set()
for entry in contents['images']:
    path=ROOT/'ios/Runner/Assets.xcassets/AppIcon.appiconset'/entry['filename']
    if path in seen:continue
    seen.add(path);size=round(float(entry['size'].split('x')[0])*float(entry['scale'].rstrip('x')));png(path,(size,size),True)
for path in [ROOT/'android/app/src/main/AndroidManifest.xml',ROOT/'android/app/src/main/res/drawable/ic_launcher_foreground.xml',*(ROOT/'android/app/src/main/res/mipmap-anydpi-v26').glob('*.xml')]:ET.parse(path)
for page in ['index.html','privacy.html','support.html','terms.html','data-control.html']:
    value=(ROOT/'docs'/page).read_text();require('<html lang="en">' in value and 'support@subtrack.example' in value,f'{page}: complete page and explicit temporary contact')
for name in ['privacy-policy.md','terms-of-use.md','support.md','local-data-control.md']:require((ROOT/'docs/legal'/name).is_file(),f'Bundled legal document: {name}')
contact=json.loads((ROOT/'store/contact.json').read_text());require(contact['requires_working_email_before_submission'] is True,'Temporary contact explicitly blocks submission')
manifest={'app':'SubTrack','locale':'en-US','prepared_date':'2026-11-06','screenshot_provenance':'Actual Flutter widget renders with fictional sample records; not physical-device captures. Compare against final signed builds.','temporary_contact':'support@subtrack.example','submission_ready':False,'submission_blockers':['Replace temporary email with monitored support mailbox','Confirm legal developer identity and store account details','Sign final builds and perform physical-device notification QA','Complete console-specific questionnaires and device-size requirements'],'assets':assets}
(ROOT/'store/asset-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('\n'.join(checks));print(f'PASS: {len(checks)} checks. Manifest records {len(assets)} PNG assets. Temporary-contact blocker remains intentional.')
