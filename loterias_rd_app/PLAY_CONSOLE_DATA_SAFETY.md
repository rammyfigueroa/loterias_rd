# Play Console Data Safety Draft

Use this as a draft while completing Google Play Console. Verify each answer before submission.

## Data collection

Recommended answer based on current code review: the app does not collect personal user data.

## Data sharing

Recommended answer based on current code review: the app does not share personal user data.

## Security practices

- Data is transmitted over HTTPS.
- No account creation is required.
- Users cannot request deletion of account data because no account system exists.

## Data types observed

- App activity/preferences: favorites may be stored locally on device through `shared_preferences`.
- No precise location, contacts, financial info, health data, messages, photos, audio, files, calendar, or identifiers were found in the Android manifest or app code reviewed.

## Important note

If analytics, ads, crash reporting, push notifications, login, or payments are added later, this Data Safety draft must be updated before submitting a new release.
