# Privacy and store questionnaire worksheet

Applies to version 1.0.0 as implemented in this repository. Recheck the final signed binary and every SDK update before submitting. These are implementation-based answers, not a certification or a substitute for the console's current definitions.

## Google Play Data safety

| Question | Current implementation answer |
| --- | --- |
| Does the app collect or share required user data types? | No: subscription records and preferences remain on-device; no analytics/ads/backend SDK. |
| Data collected off-device by developer/SDKs | None in current app. |
| Data shared with third parties by app | None in current app. |
| Account creation | No accounts or login. |
| Account deletion requirement | No account exists. Review the console's current applicability; provide local-data-control URL if a general data-control URL is requested. |
| Encryption in transit | Not applicable to local-only records; do not assert network encryption as an app feature. Follow the current console's conditional questions. |
| Independent security review | No certification claimed. |
| Advertising | No ads. |
| Financial features | Manual expense/subscription planning only; no banking, lending, investment, payments or cryptocurrency. Answer according to the current console categories. |
| Sensitive permissions | Notification permission and boot-completed scheduling support. No location, contacts, camera, microphone, SMS or accessibility access. |

User-written notes can contain any text, but are processed locally. Store categories are about collection/transmission under the console's definitions, not merely local fields. User-initiated email/support and the GitHub-hosted website have separate processing described in the policy.

## Apple App Privacy

Proposed privacy label: **Data Not Collected**, subject to checking the final binary and all SDKs. No cross-app tracking, advertising identifiers or App Tracking Transparency prompt are used. Do not declare tracking domains or request ATT permission for this version. Keep required privacy manifests provided by dependencies. Check Apple's required-reason APIs report from the final Xcode archive and declare only actual approved reasons; do not invent reason codes. The existence of SDK manifests alone is not a guarantee that the final archive passes Apple's validation.

## Age/content and commercial setup

Proposed storefront category: Finance (personal subscription/expense organization); alternative Productivity if required by reviewer feedback. This is not a regulated financial service. No ads, in-app purchases, paid subscriptions, user-generated public content, chat or gambling. Complete the live content-rating questionnaires truthfully; the final age rating is assigned by each store, not this document. Use free pricing for the MVP unless the owner changes the product plan.

## Contact and policy URLs

Temporary placeholder: `support@subtrack.example` — not monitored and must be replaced before submission.

Intended GitHub Pages URLs:
- Privacy: https://bilalyamin127.github.io/SubTrack/privacy.html
- Support: https://bilalyamin127.github.io/SubTrack/support.html
- Data controls: https://bilalyamin127.github.io/SubTrack/data-control.html
- Terms: https://bilalyamin127.github.io/SubTrack/terms.html

Confirm each URL returns HTTP 200 before putting it into either console. A public GitHub Markdown blob URL is a source view, not the preferred hosted policy URL.
