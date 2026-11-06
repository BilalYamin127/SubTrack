"""Build static public legal/support pages from the app's bundled Markdown.
No third-party build dependencies and no delete operations.
"""
from pathlib import Path
import html, re, shutil
ROOT=Path(__file__).resolve().parents[1]
DOCS=ROOT/'docs'
STYLE='''*{box-sizing:border-box}body{margin:0;background:#f7f7fc;color:#222033;font:17px/1.75 system-ui,-apple-system,sans-serif}a{color:#6543c6}header,main,footer{max-width:880px;margin:auto;padding:28px}header{display:flex;align-items:center;gap:14px}header img{width:48px;height:48px;border-radius:12px}header a{text-decoration:none;font-size:24px;font-weight:800;color:#4e328f}nav{margin-left:auto;font-size:14px;display:flex;gap:16px;flex-wrap:wrap}main{background:white;border-radius:24px;padding:40px;margin-bottom:30px}h1{font-size:36px;line-height:1.2;letter-spacing:-1px}h2{font-size:22px;margin-top:32px}p{margin:16px 0}li{margin:10px 0}footer{font-size:13px;color:#625c75}.notice{padding:16px;border-radius:12px;background:#f2edff;border-left:4px solid #7755dc}.hero{background:linear-gradient(125deg,#7755dc,#49318c);color:white;padding:32px;border-radius:18px}.hero h1{margin-top:0}.links{display:grid;gap:12px;margin:28px 0}.links a{padding:16px;border-radius:12px;background:#f7f5fd;text-decoration:none;font-weight:650}code{overflow-wrap:anywhere}p,li{overflow-wrap:anywhere}@media(max-width:600px){header,main,footer{padding:22px}main{border-radius:0}header{flex-wrap:wrap}nav{margin-left:0;width:100%}h1{font-size:30px}}'''
def inline(text):
    value=html.escape(text)
    value=re.sub(r'\*\*(.*?)\*\*',r'<strong>\1</strong>',value)
    value=re.sub(r'(https://[^\s<]+)',lambda m:'<a href="'+m.group(1).rstrip('.,')+'">'+m.group(1).rstrip('.,')+'</a>',value)
    return value

def markdown(source):
    parts=[]; paragraph=[]; in_list=False
    def flush():
        if paragraph: parts.append('<p>'+inline(' '.join(paragraph))+'</p>');paragraph.clear()
    for line in source.splitlines():
        if not line.strip(): flush();continue
        if line.startswith('#'):
            flush()
            if in_list:parts.append('</ul>');in_list=False
            match=re.match(r'(#{1,3}) (.*)',line)
            if match:parts.append(f'<h{len(match[1])}>'+inline(match[2])+f'</h{len(match[1])}>')
        elif line.startswith('- '):
            flush()
            if not in_list:parts.append('<ul>');in_list=True
            parts.append('<li>'+inline(line[2:])+'</li>')
        else:
            if in_list:parts.append('</ul>');in_list=False
            paragraph.append(line)
    flush()
    if in_list:parts.append('</ul>')
    return '\n'.join(parts)
def page(title,body):
    return f'''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="description" content="SubTrack offline subscription tracker: privacy, support and terms."><meta name="color-scheme" content="light"><title>{html.escape(title)} · SubTrack</title><link rel="icon" href="assets/app-icon.png"><style>{STYLE}</style></head>
<body><header><img src="assets/app-icon.png" alt="SubTrack calendar renewal icon"><a href="index.html">SubTrack</a><nav aria-label="Main navigation"><a href="privacy.html">Privacy</a><a href="support.html">Support</a><a href="terms.html">Terms</a></nav></header><main>{body}</main><footer>SubTrack · Offline subscription reminders<br>Temporary contact: support@subtrack.example — reserved placeholder, not monitored. A working contact must replace it before store submission.<br><a href="data-control.html">Your local data</a> · <a href="https://github.com/BilalYamin127/SubTrack">Project repository</a></footer></body></html>'''
for source,target,title in [('privacy-policy.md','privacy.html','Privacy policy'),('terms-of-use.md','terms.html','Terms of use'),('support.md','support.html','Support'),('local-data-control.md','data-control.html','Your local data')]:
    body=markdown((DOCS/'legal'/source).read_text())
    (DOCS/target).write_text(page(title,body))
hero='''<section class="hero"><h1>Subscriptions.<br>Under control.</h1><p>Track costs. Plan renewals. SubTrack keeps recurring subscriptions and bills in a private, offline workspace.</p></section><h2>Know what renews next</h2><p>Manual records, local reminders, calendar-aware renewal projections and expense insights. No account, bank connection or payment processing.</p><div class="links"><a href="privacy.html">Read the privacy policy →</a><a href="support.html">Get help with SubTrack →</a><a href="data-control.html">Understand your local data →</a><a href="terms.html">Read the terms of use →</a></div><p class="notice">Pre-release support site. The store launch pack is prepared in the repository. App-store publication is not claimed. The temporary support email is not operational.</p>'''
(DOCS/'index.html').write_text(page('Subscription reminders',hero))
(DOCS/'assets').mkdir(exist_ok=True)
shutil.copyfile(ROOT/'assets/branding/app-icon-256.png',DOCS/'assets/app-icon.png')
(DOCS/'.nojekyll').write_text('')
print('Built index, privacy, terms, support and data-control HTML pages.')
