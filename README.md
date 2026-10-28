# Multilingo

An original Flutter app for learning Italian. It works fully offline and has no ads.

> **A study project.** Multilingo is a clone of a popular language-learning app, built to experiment, explore and learn how such apps work. It is not affiliated with that app or its makers. It uses its own name, art, mascot, sounds and lessons, and none of the original's code or content. It is not for sale and is not on any app store.

## Features

- Two languages, Italian and German, each a full CEFR course A1 to C2: 55 units, 220 lessons, unit guides, stories and a sounds guide. Switch with the flag at the top left of the home screen, or pick at first launch. Each language keeps its own lessons, review words and level results. XP, gems, hearts, streak and settings are shared. The voice, the texts and the typing hints follow the language. To add a language, add content in `lib/data/content_<id>/`, one `Language` in `lib/data/languages.dart` and one case in `Course._build`.
- No ads, no tracking, no accounts.
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
- Backup and restore (Settings, Your data): one backup file named `duolingo-backup.json`, kept fresh automatically and overwritten on every save. Save it to Files or Drive, share it, or restore it from a file (also offered on first launch). At a milestone (a level passed, a new badge, a streak of 7, 14, 30, 50, 100 or 365 days, every 5th lesson) the file is rewritten at once, and the lesson result screen reminds you, at most once a day, to save a copy outside the phone. Up to 5 named restore points plus 2 automatic ones are kept inside the app. A restore or reset always saves an undo point first.
- Backup screen texts exist in English, Italian and Spanish (`lib/l10n`, follows the phone language). Add a language by copying `app_en.arb`, translating it and running `flutter gen-l10n`.

## Backup file format

Schema 3 JSON: `app`, `schema`, `id`, `createdAt`, `label`, `kind`, `appVersion`, `checksum`, `activeCourse`, `profile` (shared by every language: name, settings, gems, hearts, streak, XP) and `courses` (language id to that language's progress). Older files (schema 1 and 2) are upgraded on import. A newer schema than the app knows is refused with a clear message. The checksum detects edits and cut-off files. Frozen example files for every schema live in `test/fixtures/backups/` and must keep restoring.

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

- All progress is saved on the device (shared_preferences).
- Speech is recognised by the phone itself (Android and iOS speech services). Some phones send audio to their vendor's server for this. The app saves no audio.
- All content, art and branding are original.
