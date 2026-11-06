# SubTrack store launch pack

See [publishing checklist](../docs/release/publishing-checklist.md) and [privacy questionnaire worksheet](../docs/release/privacy-disclosures.md) before submission.

| Asset | Location | Use |
| --- | --- | --- |
| Play icon | `android/app-icon-512.png` | Google Play high-resolution icon, 512×512 |
| Play feature graphic | `android/feature-graphic-1024x500.png` | 1024×500 horizontal banner |
| Android screenshots | `android/en-US/screenshots/01-*.png` through `08-*.png` | Eight 1080×1920 portrait screenshots |
| Apple icon | `ios/app-icon-1024.png` | 1024×1024 opaque artwork; also installed in Xcode asset catalog |
| iPhone screenshots | `ios/en-US/screenshots/01-*.png` through `08-*.png` | Eight 1320×2868 portrait screenshots |
| Play copy | `android/en-US/*.txt` | Title, short/full description and release notes |
| Apple copy | `ios/en-US/*.txt` | Name, subtitle, promotional text, keywords, description and what's new |
| App Review notes | `ios/en-US/review-notes.md` | No login needed; review walkthrough |
| Contacts/URLs | `contact.json` | Central listing reference; temporary email clearly marked |
| Asset inventory | `asset-manifest.json` | Dimensions, formats and SHA-256 checksums |

Screenshot order: overview → subscriptions → add → details → upcoming → analytics → categories → settings. Sample names and amounts are illustrative. New installs start empty. The actual Flutter UI is rendered by the capture tool; compare final native builds before submission. Screenshots do not imply that a payment occurred.

The app's launcher icons are installed under `android/app/src/main/res/` and `ios/Runner/Assets.xcassets/AppIcon.appiconset/`. The vector Android adaptive icon uses a white calendar, purple renewal arrow and teal reminder dot. Master brand artwork is in `assets/branding/`. Generate raster icon sizes again with `python3 tools/export_icons.py` (requires ImageMagick). Review all masks on a real launcher; adaptive, legacy and store artworks intentionally adapt to their platform's masking rules.

Brand colors: purple `#7755DC`, teal `#16A898`, white `#FFFFFF`. No subscription-provider logos are used. Brand artwork was AI-generated for this project; review identity/trademark availability before adopting the brand commercially. Screenshot font is Roboto under its included OFL license (`tools/fonts/OFL.txt`).

**Public hosting:** HTML pages are ready, but GitHub returned HTTP 403 when the integration tried to enable Pages. Follow [owner setup](../docs/release/github-pages-setup.md); do not use unverified `github.io` URLs in a submission.

**Submission blocker:** `support@subtrack.example` is reserved and does not receive email. Replace it with your working mailbox, confirm the legal developer identity, sign the release builds and complete the store questionnaires/device checks before launch. Publishing documents in GitHub does not publish the mobile app.
