# Scripture Quest V2 — first reading design pass

Scope: Quest Hub / Today and Bible Reader presentation only. Based on
`ddd3412778cf45206e6f9bddae9067c82866214b`; checkpoint branch
`v2/pre-reading-design`; delivery branch `v2/reading-design`.

## Changes

- Today presents one existing reading quest first, with a real resume-reading
  fallback and clear completed-day state. Optional quests and weekly goals sit
  below the primary reading and reflection actions.
- Shared paper/sepia/night presentation, teal controls, Lora headings and Inter
  interface text. Mobile single-column layout has a bounded desktop width.
- Reader exposes passage selection and text settings, supports tapping verses
  for existing save/highlight/reflection actions, and respects system text scaling.
- Chapter completion appears after the passage instead of covering verses;
  previous/next controls remain visible. Existing time requirements are explained.
- Quest completion presentation and keyboard-scrollable reflection sheets match
  the reading experience. Shared TaskCard changes are opt-in for this screen.

## Preserved

No changes to providers, services, models, Bible assets, dependency manifests or
lockfile, iOS/Android project files, XP formulas, storage, reading thresholds,
quest generation, onboarding, plans or games. Navigation remains three tabs.
Existing reader loading, timers, eligibility and task-routing methods were
compared with the checkpoint and match after ignoring formatting/comments.

## Verification and outstanding gates

- Saved analysis before interruption: zero errors across lib; warnings remain.
- Final diff whitespace check passes; Dart formatter parses the changed files.
- On resumption the external package cache was absent. After restoring packages,
  final full-lib analysis reports zero errors (123 warnings/info remain).
- Test command stopped before execution: cached Flutter tool snapshot version
  mismatch. No tests are claimed as passed.
- Flutter Web build, actual-screen widget tests, visual browser review and iPhone
  execution have not been verified here. This is a review candidate, not a claim
  of runtime-validated completion. Existing tests largely exercise stand-in
  widgets rather than these actual screens.
- GitHub push requires authentication not present in this workspace.

## Codespaces validation

Use the existing Flutter 3.32.8 installation. From the repository directory,
with any currently running preview stopped:

```sh
flutter pub get --enforce-lockfile
flutter analyze
flutter test
flutter build web --release --no-pub
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080 --no-pub
```

Check Today -> featured reading -> verse actions -> chapter completion -> return
home; journal save, highlights/bookmarks after reload, night/sepia, large text,
small phone width, completed and empty quest states. Do not start Phase 2 until
owner review. The existing progression rules, including different chapter and
quest time gates, intentionally remain unchanged.
