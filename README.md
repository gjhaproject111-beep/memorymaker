# Photographic Memory

**Remember More**

A private, single-user, local-first verbatim memory trainer. Read a passage
once, recall it exactly, see precisely what you got wrong, and repeat until
you reach 100% word-for-word accuracy — then get tested on it again later,
without warning, at 10 minutes, 24 hours, 3 days, 7 days, and 30 days.

This is not a general reading-comprehension app. It measures **verbatim**
recall: word choice, word order, and spelling all count.

No login. No social features. No backend. Everything lives on your device.

---

## First-time setup (do this once)

This repository ships the Dart/Flutter source (`lib/`, `test/`,
`pubspec.yaml`, `assets/`) but **not** the generated native platform
folders (`android/`, `ios/`, etc.) — those are large, mostly-boilerplate,
and best generated fresh by your own Flutter SDK rather than hand-written.

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel) and confirm it with `flutter doctor`.
2. From a **separate, temporary folder**, generate a scaffold project and copy just the native platform folder(s) you need into this repo, so your existing `lib/`, `test/`, and `pubspec.yaml` are never touched:
   ```bash
   flutter create --platforms=android --project-name photographic_memory /tmp/pm_scaffold
   cp -r /tmp/pm_scaffold/android ./android
   # Optional, if you also want to build for iOS later:
   # flutter create --platforms=ios --project-name photographic_memory /tmp/pm_scaffold_ios
   # cp -r /tmp/pm_scaffold_ios/ios ./ios
   ```
3. Commit the resulting `android/` folder. From then on, `codemagic.yaml` and your local builds will use it as-is (see below — Codemagic will also self-heal and generate it on the fly if you ever forget this step).

## Build & run

```bash
flutter pub get
flutter run            # run on a connected device/emulator
flutter build apk      # release APK
flutter build appbundle
```

## Test

```bash
flutter test
```

The most important test suite is `test/text_comparison_service_test.dart`,
which exercises the word-alignment comparison engine against the 12+
scenarios called for in the spec: perfect recall, a missing word, an extra
word, a substitution, adjacent transpositions, multiple simultaneous error
types, punctuation/capitalization insensitivity (and the opt-in strict
mode), repeated words, near-miss spelling, an empty recall, a very long
recall, determinism, and mastery-threshold detection.

## Architecture

```
lib/
  core/
    models/        Plain Dart data classes + hand-written JSON (de)serialization
    services/       TextComparisonService, ScoringService, RetentionSchedulerService,
                     PassageSelectorService, BackupService — pure business logic
    repositories/   Local JSON-file persistence (PassageRepository is read-only,
                     backed by the bundled asset; Session/Settings are read-write)
    state/          Services (a tiny service locator) + AppDataBus (a "please
                     refetch" signal screens listen to)
    theme/          Colors, type scale, ThemeData
    utils/          ID generation, date formatting — no external deps
  features/
    onboarding/     First-run welcome + personal baseline
    home/           Dashboard
    training/       The Read → Recall → Results → Review → Repeat flow,
                     reused for delayed-retention tests
    retention/      Per-passage retention timeline
    library/        Browse passages, see history
    progress/       Trend charts (own accuracy over time)
    analytics/      Error-type trends, reading speed, difficulty breakdown
    settings/       Every configurable option
  widgets/          Shared UI: buttons, cards, the accuracy ring, a small
                     hand-rolled line/bar chart (no charting package)
  app.dart          MaterialApp + first-run routing
  main.dart         Entrypoint
```

### The comparison engine (`core/services/text_comparison_service.dart`)

Word-level Needleman–Wunsch / Wagner–Fischer global alignment between the
original passage and the recalled text, classifying each word as correct,
missing, extra, substituted, a spelling slip (small edit distance), or part
of an adjacent transposition ("wrong order"). Order accuracy is reported
separately via longest-common-subsequence length. See the doc comment at
the top of that file for the full reasoning and its one deliberate scope
limit (adjacent-only transposition detection).

### Persistence

Everything is plain JSON on local disk (`path_provider`'s app-documents
directory), written via a temp-file-then-rename so a crash mid-write can
never corrupt existing data — this is also what makes session recovery
(spec §30) safe. There is intentionally no database dependency for a
single-user app this size.

### Design system

Deep plum (`#1D1026`) / dark plum (`#281633`) background, peach
(`#F6B39D`) as the primary action color, cream (`#FFF5EF`) text, muted
rose (`#B987A7`) as a secondary accent. See `core/theme/`.

## Known limitations / natural next steps

- **Export/Import** currently round-trips through a local backup file in
  the app's own storage (genuinely functional — export then import
  restores everything) but doesn't yet hand the file to Android's share
  sheet or a file picker. Adding `share_plus` and/or `file_picker` is a
  clean, self-contained follow-up.
- **Custom passages, OCR/PDF import, voice recall** — deliberately left as
  extension points (spec §38), not built in V1.
- Order-error detection covers **adjacent** transpositions only (see the
  comparison engine's doc comment) — reordering spread further apart shows
  up as substitutions instead of a dedicated "wrong order" error.
- This project was authored without a local Flutter SDK available, so
  while every file was written carefully and the alignment algorithm was
  manually traced through its test cases, none of it has been run through
  `flutter analyze` / `flutter test` yet. **Please run both before your
  first build** and treat any warnings as the first thing to fix.

## GitHub / CI

- `.gitignore` excludes build output, IDE folders, and any signing
  secrets.
- `codemagic.yaml` builds a release APK + AAB. It self-heals the
  `android/` folder if it isn't committed yet, runs `flutter analyze` and
  `flutter test` before building, and reads signing credentials from a
  Codemagic environment variable group (`android_signing`) — nothing
  secret is committed.
