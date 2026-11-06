# Pulse Finance

Pulse Finance is an offline-first Flutter allowance and expense tracker for
Android and iOS phones and tablets, plus macOS. It recreates the dark dashboard, violet
accent, transaction log, spending calendar, analytics, settings, and income /
expense entry flows shown in the desktop reference.

On macOS, the desktop layout uses a persistent sidebar, system typography,
keyboard shortcuts (`⌘N` for a new expense and `⌘1`–`⌘5` to switch sections),
and centered dialogs for desktop workflows.

## Features

- Monthly or weekly allowance cycles with automatic refill when the app opens
  or resumes.
- Adjustable allowance, daily spending target, currency, accent palette,
  categories, and student profile.
- Expense and allowance-credit records with date, category, payment method,
  and notes.
- Dashboard balance and daily spending summaries, searchable transaction log,
  spending calendar, category allocation, and daily spending chart.
- A first-run swipeable app tour, with the swipe-to-delete gesture explained and
  an option to replay the tour from Settings.
- Inter typography bundled for offline use.
- Local on-device persistence. Data is not sent to a server.
- JSON backup import/export and CSV transaction export through the platform
  share sheet.

## Run

Install Flutter for your platform, then from this project directory run:

```shell
flutter pub get
flutter run
```

For Android, use an Android SDK and emulator or connected device. Building
macOS or iOS applications requires macOS and Xcode.

## Validate

```shell
flutter analyze
flutter test
```

The sample data is local demonstration content. Select **Settings → Reset demo
data** to restore its default allowance, profile, and sample transactions.
