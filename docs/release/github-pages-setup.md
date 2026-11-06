# Activate the public policy/support URLs

The static HTML pages are committed under `docs/`. They do not need a build framework, login or paid service.

## Current status

Repository upload completed. Automatic GitHub Pages enablement was attempted on 6 November 2026. GitHub returned HTTP 403, `Resource not accessible by integration`, for the Pages creation endpoint. The connected integration can push source but cannot change this Pages setting. Public `github.io` URLs therefore remain **prepared, not verified live**. This is a token permission limitation, not a failure to generate the documents.

## One-time owner action

1. Open https://github.com/BilalYamin127/SubTrack/settings/pages while signed in as the repository owner.
2. Under **Build and deployment**, choose **Deploy from a branch**.
3. Choose branch **main**, folder **/docs**, and save.
4. Wait for the Pages build/deployment to finish. Use the URL shown by GitHub. If the actual URL differs, update `store/contact.json`, store field reference, worksheets and relevant document links before submission.
5. Open each page without login and confirm it returns a successful response:
   - https://bilalyamin127.github.io/SubTrack/
   - https://bilalyamin127.github.io/SubTrack/privacy.html
   - https://bilalyamin127.github.io/SubTrack/support.html
   - https://bilalyamin127.github.io/SubTrack/terms.html
   - https://bilalyamin127.github.io/SubTrack/data-control.html
6. Replace the temporary email with a monitored support address in all source documents and metadata. Run `python3 tools/build_launch_pages.py`, commit the updated pages, rebuild the app so its bundled policy matches, and check the public pages again.

The public source documents are already readable in the repository:
- Privacy: https://github.com/BilalYamin127/SubTrack/blob/main/docs/legal/privacy-policy.md
- Support: https://github.com/BilalYamin127/SubTrack/blob/main/docs/legal/support.md
- Terms: https://github.com/BilalYamin127/SubTrack/blob/main/docs/legal/terms-of-use.md

Use the final hosted HTML URLs for store submission once active. Do not claim the current temporary mailbox is operational or that the mobile app is published just because these pages are hosted.
