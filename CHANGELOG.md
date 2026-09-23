# Changelog

## [1.0.0] - Unreleased — Version 1

### Added
- Core verbatim memory training loop: Read → Recall → Review → Repeat → Mastery.
- Word-level sequence-alignment comparison engine (correct / missing / extra /
  substituted / spelling / order-error detection), with unit tests.
- Scoring: one-read accuracy, exact word accuracy, order accuracy, omission
  rate, substitution rate, extra-word rate, spelling error rate, attempts to
  mastery.
- Delayed retention testing at 10 minutes, 24 hours, 3 days, 7 days, 30 days.
- Local, offline-first persistence (no account, no server) via JSON files in
  app documents storage.
- Built-in passage library across General / Science / History / Education /
  Nature / Technology, at Easy / Medium / Hard / Advanced difficulty.
- Personal baseline flow on first run, using unseen passages.
- Home dashboard, Training flow, Progress, Analytics, Library, Settings.
- Session recovery after an interrupted training session.
- Plum + Peach premium visual theme, responsive bottom-nav (phone) / sidebar
  (tablet & desktop) navigation.
- Codemagic CI configuration for Android builds.
