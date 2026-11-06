# SubTrack – Subscription Reminder

An offline Flutter app for manually tracking recurring subscriptions and bills. No account, backend, bank connection, payment processing, or paid service is required. Records stay in Hive CE on the device. Android cloud backup is disabled.

## Run

Developed with Flutter 3.47.9 / Dart 3.13.7. Install the stable Flutter SDK, then:

```sh
flutter pub get
flutter run
```

Android and iOS are the primary targets. `flutter run -d chrome` provides a responsive web preview with browser-local storage; local notifications are unavailable on web. Deleting browser storage removes web records.

## Architecture (MVVM)

- `lib/models`: immutable subscription and category records, JSON serialization.
- `lib/repositories`: Hive CE persistence for records, categories, settings.
- `lib/services`: calendar billing math, currency-separated totals, pure reminder planner and native notification adapter.
- `lib/view_models`: Riverpod `AppViewModel` owns application state, CRUD, status changes, settings, persistence and reminder refreshes.
- `lib/views`: Material 3 views consume state and call view model commands.
- `lib/main.dart`: dependency injection, GoRouter routes, theme and app lifecycle.

The eight screens are dashboard, subscriptions, editor, details, upcoming renewals, analytics, categories and settings. The layout adapts from bottom navigation to a desktop sidebar. Light, dark and system themes are supported. Mobile categories and settings are accessible via the overview settings icon.

## Billing rules

Only active records contribute to totals. Each currency is summarized separately; no exchange-rate conversion is attempted. Monthly equivalents are weekly × 52 / 12, monthly × 1, quarterly / 3, half-yearly / 6 and yearly / 12. Custom intervals use `price × 365.2425 / intervalDays / 12`; yearly equivalents are monthly equivalents × 12. These are projections, not payment history.

The next-renewal field is the recurrence anchor. Its original day is retained: January 31 → February 28/29 → March 31. Leap-day yearly renewals return to February 29 in leap years. The first-payment date is historical context, not a second recurrence anchor. Set an intended 31st on a month containing that day to retain a 31st schedule. Editing unrelated fields preserves the stored anchor rather than replacing it with a clamped date. Past anchors roll forward to the first occurrence on or after today. Weekly/custom intervals use calendar days, avoiding DST duration drift.

Upcoming groups contain the next projected renewal for each active subscription, partitioned into today, 1–7 days, 8–30 days and later. Pausing/cancelling affects the local record only. Resume projects forward from the existing anchor and never confirms a payment.

## Reminders

Enable local reminders in Settings and grant device notification permission. Each subscription supports 7, 3, 1 and 0 days before renewal, at 09:00 local time. Duplicate lead days are removed. Past reminder times are skipped. A same-day alert is skipped if 09:00 has already passed.

The pure planner selects the earliest 60 future alerts within one year, across all active records. This stays below iOS's 64 pending-notification limit. Open the app regularly to replenish the rolling schedule. Launch, foreground resume, subscription mutations and settings changes rebuild reminders. Rescheduling is serialized and cancels old pending alerts before scheduling unique IDs. Android boot/package-update receivers restore scheduled alarms; timezone is refreshed on app resume. Android uses inexact alarms and does not require exact-alarm permission. Permissions, OS power settings and time changes can affect delivery; reopen after changing the device clock or timezone. Disabling reminders or clearing data cancels alerts.

## Validate

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build web --release
```

Tests cover month ends, leap years, intervals, old anchors, currency separation, inactive records, persistence, view model commands, reminder deduplication/capacity, and a mobile create/details/analytics flow plus desktop layout. The notification planner is tested; actual delivery requires a physical Android/iOS device. Verify permission denial/grant, foreground/background delivery, edit/pause/delete cancellation, reboot, and timezone changes on devices before distribution.

## Android release

Install Android SDK, accept licenses with `flutter doctor --android-licenses`, then configure your own upload key. Never commit keys/passwords. Create `android/key.properties` from `android/key.properties.example`. A configured key signs release APK/AAB builds. Without a key the release output is unsigned and must be signed before installation/distribution.

```sh
flutter build appbundle --release
flutter build apk --release
```

For a locally installable test build use `flutter build apk --debug`. Package ID: `com.bilalyamin.subtrack`. Adjust it before publishing if needed.

## iOS release

Requires macOS, Xcode, Apple signing credentials and a physical-device delivery check.

```sh
flutter build ios --release --no-codesign
open ios/Runner.xcworkspace
# Select signing team and a unique bundle identifier in Xcode, then archive.
flutter build ipa --release
```

CI includes static analysis, tests, web build, an Android debug APK plus unsigned release AAB, and an unsigned iOS app bundle. Download these from the workflow run’s Artifacts section. Unsigned builds require your signing credentials before distribution. Store upload/signing is deliberately separate. This repository does not contain signing secrets or claim store approval.

## Store launch pack

[Preview the icon, feature graphic and screenshots](store/PREVIEW.md). The repository includes eight Android and eight iPhone screenshots, platform launcher icons, English listing copy, privacy/terms/support pages and a [publishing checklist](docs/release/publishing-checklist.md). Settings includes offline legal/support documents.

Public policy/support pages are prepared but hosting is not enabled: the integration received GitHub HTTP 403 for the Pages setting. Follow the [one-time owner setup](docs/release/github-pages-setup.md). Intended GitHub Pages base URL: `https://bilalyamin127.github.io/SubTrack/`. The temporary contact `support@subtrack.example` is explicitly non-operational and must be replaced with a monitored mailbox before store submission. Owner signing, store-console details and physical-device notification checks are still required; assets do not imply the app is already published.

Regenerate/validate the launch pack:

```sh
python3 tools/export_icons.py
python3 tools/build_launch_pages.py
flutter test tools/screenshots_test.dart --no-pub
python3 tools/validate_launch_pack.py
```

Image exports require ImageMagick. Roboto is bundled under its [OFL license](assets/fonts/OFL.txt). Capture tooling uses in-memory sample records and does not open the user's database or remove files.
