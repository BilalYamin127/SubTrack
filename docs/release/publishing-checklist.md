# SubTrack publishing checklist

Launch pack prepared: 6 November 2026. This pack prepares repository assets; it does not submit or publish the app to either store.

## Ready in this repository

- Android high-resolution icon, 512×512 PNG.
- iOS App Store icon, 1024×1024 opaque PNG.
- Platform launcher icon sets; Android adaptive/round icon resources and iOS asset catalog.
- Google Play feature graphic, 1024×500 PNG.
- Eight Android listing screenshots, 1080×1920 PNG, rendered from actual Flutter UI.
- Eight iPhone listing screenshots, 1320×2868 PNG, rendered from actual Flutter UI with iOS target styling.
- English store titles, descriptions, keywords, release notes and App Review notes.
- Privacy policy, terms, support and local-data-control pages; offline copies in app Settings.
- Data safety/App Privacy worksheet, asset inventory, reviewer instructions and submission checklist.
- Build/test CI and unsigned release-build workflow from the app implementation.

Screenshot sample records are fictional, are injected only in the capture tool, and are not shipped as user data. The captures are Flutter widget renders, not physical-device screenshots. Visually compare final signed builds against the images, and replace captures if the final app/platform renderer differs or a store reviewer requires native device/simulator screenshots. Do not add unsupported features to marketing assets.

## Must complete before submitting

1. **Working support contact:** replace `support@subtrack.example` everywhere, including bundled policy/support documents, generated HTML, metadata and reviewer notes. The current reserved placeholder cannot receive mail. Run `python3 tools/build_launch_pages.py` after changing source legal documents. Verify the final public pages and in-app copies show the working address. Update the effective date when policy substance changes.
2. **Developer details:** confirm the developer's legal/display identity, country, address, phone and any trader/non-trader status requested by the stores. Do not treat the repo username as verified legal identity. Review legal text for the intended countries.
3. **Store accounts:** finish Google Play Console and Apple Developer/App Store Connect account setup, identity verification, agreements and any required payment/tax details. Do not put credentials into Git.
4. **App identifiers:** verify availability/ownership of `com.bilalyamin.subtrack` and the iOS bundle ID. Choose immutable store IDs carefully before first publication.
5. **Signing:** create/secure the Android upload key and enable Play App Signing. Use `android/key.properties.example`; keep real key/password files private. Configure Apple team, certificates and provisioning. Unsigned artifacts cannot be distributed to end users as-is.
6. **Versioning:** confirm `version: 1.0.0+1`, increase build numbers for subsequent uploads, and select the release countries and free pricing for this MVP.
7. **Build:** run format/analyze/tests; build signed Android AAB and signed iOS archive/IPA. Check the latest Play target-API requirements, supported SDK versions and Apple's accepted Xcode/SDK requirements against the actual submission date. CI compilation is not store validation.
8. **Physical-device QA:** test permission denial/grant; background/on-day reminders; edit/pause/resume/remove rescheduling; reboot; date/timezone changes; monthly 29th/30th/31st and leap-year schedules; custom intervals; multiple currencies; large text; dark mode; TalkBack/VoiceOver; first-install empty state; offline restart and data persistence. Use only disposable sample records when testing destructive app controls. This preparation task did not execute data-clearing commands.
9. **Privacy review:** inspect the final binary and third-party dependencies, verify privacy manifests/required-reason APIs and encryption/export compliance answers. Use the worksheet, then answer each console's current questions truthfully. Do not claim an independent security certification or add unused tracking permissions.
10. **Listing:** upload the icon, feature graphic and eight screenshots into the correct locale/device slots. Google Play screenshot images are 9:16 and meet the minimum dimensions. The iPhone set is 1320×2868 portrait; check the current App Store Connect display slot accepts that size. Prepare additional iPad captures if you keep iPad support and the console requires them; do not stretch phone images into iPad screenshots. Add actual tablet screenshots before enabling an Android tablet-focused listing.
11. **Policy URLs:** confirm privacy/support/terms/data-control HTTPS pages return 200 and the contact is working. Use hosted HTML, not a raw Markdown file. Keep the privacy policy accessible without login.
12. **Console forms:** complete content rating, target audience, ads (none), app access (all functionality without login), Data safety/App Privacy, category and any current financial-features declaration. No banking, lending, investments or payments exist in this app. Select rating answers based on actual content, not a guessed age badge.
13. **Testing/review:** upload to internal testing/TestFlight first. Follow any production-access testing requirements applicable to the Play developer account; those depend on account type/creation date and current policy. Supply a real reviewer contact and no demo credentials, because there is no login. Monitor review feedback and notification behavior.
14. **Production:** review the signed build, listing, screenshots and privacy/contact pages together, then submit and choose rollout settings in the owner-controlled consoles. Keep signing backups and a post-launch support plan.

## Release artifacts

GitHub Actions builds an Android debug APK, unsigned Android release AAB and unsigned iOS app bundle. These are for preparation/testing; final store uploads need owner-controlled signing. Android source signing is intentionally unsigned when no private upload key is configured.

## Screenshot reproduction

```sh
flutter pub get
flutter test tools/screenshots_test.dart --no-pub
python3 tools/validate_launch_pack.py
```

The capture tool uses an in-memory Riverpod view model, sample data and the OFL-licensed Roboto font. It never opens the user's Hive box and never removes files. It overwrites only its declared screenshot PNG paths. Existing production records are not used.
