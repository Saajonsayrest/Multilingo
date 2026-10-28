# Multilingo

An original Flutter app for learning Italian. Lessons work offline and there are no ads. Progress is kept on the phone and saved to the cloud when you are online.

> **A study project.** Multilingo is a clone of a popular language-learning app, built to experiment, explore and learn how such apps work. It is not affiliated with that app or its makers. It uses its own name, art, mascot, sounds and lessons, and none of the original's code or content. It is not for sale and is not on any app store.

## Features

- Two languages, Italian and German, each a full CEFR course A1 to C2: 55 units, 220 lessons, unit guides, stories and a sounds guide. Switch with the flag at the top left of the home screen, or pick at first launch. Each language keeps its own lessons, review words and level results. XP, gems, hearts, streak and settings are shared. The voice, the texts and the typing hints follow the language. To add a language, add content in `lib/data/content_<id>/`, one `Language` in `lib/data/languages.dart` and one case in `Course._build`.
- No ads and no tracking. An account is optional and only used to save your progress.
- Level checkpoints: after each level a 20 question test (80% to pass) opens the next level. Best scores and badges show in Profile.
- 9 exercise types: word-bank translation both ways, multiple choice, picture choice, match pairs, listen and type, listen and choose, fill the gap, speaking practice
- Teach first: each lesson shows "New word" cards (picture, meaning, sound), then asks those words before the next group. Tap an underlined word in a sentence to hear it and see its meaning. The first lesson of a unit shows the unit tips.
- Italian text-to-speech with normal and slow playback
- Hearts that refill over time, XP, gems, daily goal
- Streak with streak freeze, and a month streak calendar in Profile
- Daily reminder (Settings): you pick the time, it skips days you already practised, and the text follows your streak. The app asks for notification permission only when you turn it on.
- Speaking exercises use the microphone: tap the mic, say the phrase, and the phone's speech recognition checks it in the language you learn. It is forgiving of small mistakes. A button below lets you skip it when you cannot speak. The app asks for the microphone only on your first tap.
- Smart review (spaced repetition) and a mistakes review
- Stories with comprehension questions
- Pronunciation guide (sounds and letters)
- Offline weekly leagues with promotion and demotion
- Daily quests and badges
- Shop: refill hearts, streak freeze, double XP boost
- Profile with weekly XP chart, settings, light and dark theme
- Fox mascot (18 expressions as SVG in `assets/mascot/`, made by `tool/gen_mascot.dart`, shown by `lib/core/mascot.dart`), 32 status and reward symbols in `assets/status/`, brand symbols in `assets/brand/`, and an app icon built from the fox. Preview sheet: `assets/design/mascot_sheet.png`.
- Android home-screen widgets: streak, daily goal and next lesson. They update by themselves and Pip's mood follows your day (`lib/state/widget_sync.dart`, `android/app/src/main/kotlin/io/rea/multilingo`). iPhone widgets are not built yet (they need a WidgetKit extension in Xcode).
- Cloud save (Settings, Account and cloud save), built on Firebase. After the first-run screens the app makes a silent account and saves your progress a few seconds after each change. Nothing is asked up front. Add an email and a password to get your progress back on a new phone or after a reinstall. The lesson result screen suggests this, at most once a day.
- With no connection nothing is lost: the phone keeps the progress and sends it later. If two phones changed the same progress, you choose which copy to keep, and the other one is kept as a restore point.
- Five restore points live in your account: milestones (a level passed, a new badge, a streak of 7, 14, 30, 50, 100 or 365 days, every 5th lesson), the first save of each day, and one before every reset or restore. A reset is refused while you are offline, so it can always be undone. Signing out clears the phone only after the cloud holds everything. You can delete the account and all its data from the same screen.
- Account screen texts exist in English, Italian and Spanish (`lib/l10n`, follows the phone language). Add a language by copying `app_en.arb`, translating it and running `flutter gen-l10n`.

## Cloud save

The save is one Firestore document, `users/{uid}`: `schema`, `rev`, `savedAt`, `appVersion`, `activeCourse`, `profile` (shared by every language: name, settings, gems, hearts, streak, XP) and `courses` (language id to that language's progress). Restore points are `users/{uid}/checkpoints/c0` to `c4`. `rev` goes up by one on every save, and `firestore.rules` accepts only that, so two phones can never overwrite each other unseen. The rules also keep each account to its own documents and refuse any other field or slot. A newer `schema` than the app knows is refused with a clear message.

`lib/domain/cloud_save.dart` holds the format and the rule that decides what a sync does. `lib/state/cloud_sync.dart` runs it. The tests use in-memory fakes of Firebase (`test/support/cloud_fakes.dart`).

### Use your own Firebase project

The Firebase config of the original author is not in this repository, and the app does not build until you add your own:

1. Make a Firebase project (console or `firebase projects:create <id>`). The free plan is enough.
2. `cp firebase.template.json firebase.json`
3. `flutterfire configure --platforms=android,ios` writes `lib/firebase_options.dart` and adds your app ids to `firebase.json`. It also edits files in `android/` and `ios/`. The app starts Firebase from `firebase_options.dart` alone, so you can undo those edits with `git checkout android ios`.
4. `firebase deploy --only firestore,auth` creates the database, turns on anonymous and email sign-in, and publishes `firestore.rules`.
5. `./setup.sh rules` signs in as two throwaway users and checks that every rule holds. It deletes what it made.

`lib/firebase_options.dart`, `firebase.json`, `.firebaserc` and any Firebase key file are listed in `.gitignore` and must stay out of Git.

## Run

First time on a new machine: `./setup.sh s` (checks Flutter, gets packages, builds translations, installs iOS pods). Then `./setup.sh r` to run. Run `./setup.sh` alone to see every shortcut.

```
./setup.sh s      first-time setup
./setup.sh r      run the app
./setup.sh t      run tests
./setup.sh art    rebuild fox art, app icon and launch screens
```

Plain Flutter works too: `flutter pub get`, `flutter run`, `flutter test`.

## Structure

- `lib/domain`: pure Dart rules (models, exercise generator, leagues, quests)
- `lib/state`: app state and the controller with all game rules
- `lib/data`: course content
- `lib/features`: one folder per screen group
- `lib/core`: theme, shared widgets, speech and feedback

## Notes

- Progress is saved on the device (shared_preferences) first, so the app is fast and works offline. The cloud holds the safe copy.
- Android's own app-data backup is turned off (`android:allowBackup="false"`), so the cloud save is the only backup and an old copy is never restored over a newer one. The app needs the internet permission for the cloud save, which is declared in the main manifest.
- Speech is recognised by the phone itself (Android and iOS speech services). Some phones send audio to their vendor's server for this. The app saves no audio.
- All content, art and branding are original.
