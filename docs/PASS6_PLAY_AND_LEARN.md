# Pass 6 — Play & Learn 2.0

Required parent: `12d8b0379e013966e3ab5501a3ff3e85ca5a75bb`, including the original StorageService startup fix. Recovered that exact full-history bundle and fast-forwarded the surviving Pass 5 checkout. No fix recreation or storage changes. Existing uncommitted preview configuration is excluded from this pass.

## Product

Play & Learn is a catalog-backed library with Word Search, Crosswords and Classics filters, completion states, visible level/XP, personal best hint counts, and Scripture context. Learn still retains chapter learning, evidence finding, Scripture Connections, Codex and Remembered Scripture. The five-tab structure and approved Light/Dark themes remain.

Six new activities: three word searches and three small connected crosswords, based on Psalms 23, John 1 and John 3. Each has five words. Authored clues identify the exact verse; source text is loaded from the bundled KJV and checked before play. These are direct-word observations, not theological trivia or a claim to comprehensive understanding. No Bible assets or red-letter metadata changed.

Word Search supports Gentle (forward horizontal/vertical) and Challenge (also diagonal/reverse), deterministic seeded reshuffling and endpoint selection. A selected starting letter can be cancelled; hints identify a start without completing the word. Crossword clues share crossing cells and use a whole-answer field with platform keyboard input; wrong attempts carry no penalty. Answer reveals count as hints. Each crossword contains all five connected answers, with adjacency/end constraints, rather than independent word slots. Runtime generation fails explicitly if future authored content cannot form a valid grid.

Puzzles show each source verse, link to the reader, and offer passage evidence, chosen-verse remembering and the existing Pass 5 NextActionPanel after completion. Chapter quiz results retain Quick/Standard/Deep and add relevant puzzle/evidence/memory/continuation links. Existing Scripture Connections remain available through Learn and Codex. Puzzles do not automatically unlock discoveries or mark Scripture read/remembered.

Matching, Verse Scramble, Book Order and Emoji Parables retain their game rules and difficulties. They now use the activity completion boundary, have saved completion state, explicit replay messaging and retryable saving. Result links return to actual session references for Matching/Scramble, reviewed parable context references for Emoji Parables, and Genesis 1 as a starting reading destination for Book Order. The existing practice libraries remain accessible.

## Architecture

- `models/activities/activity.dart`: typed family, stable identity, passage, clue and XP metadata.
- `data/activities/activity_catalog.dart`: six authored puzzle registrations, four classic adapters, existing parable context links, validation and passage lookup. It uses canonical PassageReference and validates relationships through Pass 5 ConnectedCatalog.
- `services/activities/puzzle_engine.dart`: provider-free grid generation, straight-line selection and connected crossword placement.
- `services/activities/activity_history.dart`: additive per-user completed-at, best-hints and pending-delivery records; serialized writes; corrupt records block writes without replacement. It never owns user balances.
- `screens/activities/activity_screen.dart`: transient board/input state, source loading, completion UI and shared Scripture follow-ups. Unfinished boards are intentionally transient; earned history and bests persist.
- AppProvider adds a small completion adapter and history getter, using its existing serialized exploration boundary and existing user/quest/achievement writers. No provider decomposition or separate economy. Its size changes from 6,051 to 6,093 lines (+42).

## Rewards and compatibility

One reward identity per catalog activity: `activity:<stable-id>`. Difficulty, randomized seeds, restart and replay cannot mint new identities. New puzzles use the existing ten-base-XP learning scale and existing streak adjustment. Classic base XP values are retained. The UI reports the actual total XP delta, which may include an eligible quest or achievement.

History is written pending before rewards. XP uses the existing UserService receipt; quest progress uses existing credited-activity identities. Delivery is settled only after the integration operations return. Retrying after a failed reward write resumes pending work and cannot pay that receipt twice. This is retryable multi-key delivery using existing protections, not a claim that SharedPreferences became transactional.

Only first-completion/pending puzzle deliveries credit eligible passage-matched learning quests. Replays do not advance later quests. Classic sessions mix passages and therefore deliberately do not fabricate a passage target for Daily/Weekly goals. New activities never call reading completion or emit a reading event.

Existing learning-game count is preserved as a baseline. Distinct catalog completions add to it, and existing thresholds (1/5/15) and Book Order/Emoji one-off achievements use the existing guarded unlock writer. Replays no longer inflate the counter. Historic classic XP is retained; the old system has no per-game permanent receipts, so the first completion after upgrading can earn one new catalog reward. No past completion metadata is invented, removed or clawed back. There are only ten current catalog activities, so a new profile cannot reach fifteen distinct activities until the library grows; that existing achievement remains for future content and existing users.

All existing saved IDs, user records, Journey/reading state, discoveries, memory sessions, journals, settings and prior reward receipts remain. New keys: `activities_v1_<uid>` and `activities_legacy_count_<uid>`.

## Mobile / visual

Existing semantic themes and cards; compact XP identity in the hub so activities appear sooner. Grids retain 44-pixel cells and horizontal scrolling rather than shrinking letters and touch targets. Crossword input appears before the grid, and selecting a clue returns to the answer area. All content scrolls vertically, including chapter quiz results and classic-game completion panels. Grids expose row/column/letter semantics; input uses a labeled native text field. No timed pressure or new animation behind Scripture. This is widget-level accessibility work, not VoiceOver/native certification.

## Validation

Final validation: 85 tests passed (75 existing plus nine new logic tests and one continuous UI test with all three UI scenarios). Analyzer: zero errors, 92 preexisting warnings and 26 preexisting informational diagnostics. Production Flutter Web release build succeeded. The 12 new screen/theme/size combinations and completion result were rendered and inspected. The original startup fix and both startup tests remain unchanged. Tests cover catalog/source words, crossword crossings, word-search paths across 30 seeds and both difficulties, incomplete-submit rejection, concurrent completion/replays, best-hint persistence/restart, legacy count preservation, learning quest integration without reading credit, continuation reads, pending recovery/corrupt history and failed XP persistence. Widget tests exercise both themes at phone/desktop widths, real crossword completion and word-search endpoint completion/replay. Previous regressions, including startup cold-load/failure retry, remain in the full run.

## Explicit deferrals / observations

- Larger crossword sets, extra word-search modes, timelines, geography, Who Said It, more games and broad Journey/content expansion.
- Unfinished puzzle session resume, separate best records by difficulty, richer collection milestones and a full activity recommendation algorithm. Current guidance stays the existing Pass 5 resolver.
- Full native release/iPhone/VoiceOver checks, backup/restore, full AppProvider decomposition, third-theme expansion and comprehensive bug hunt.
- The 19 unmatched red-letter verses remain untouched pending trusted review; the previously reported reading-timer concern is not certified by this work.
- Existing legacy game content/fallbacks are retained; a comprehensive trusted-content audit of those older pools remains deferred. Newly added puzzle words are verified against bundled Scripture.
- Existing notification-plugin diagnostics in headless tests remain a platform-validation concern, not a new startup fix.
- The local analyzer snapshot crashed before project analysis. Restored the exact Dart 3.8.1 snapshot from the official SDK archive; no application dependency/SDK version upgrade.

## Future registration contract

Use a new stable ID for genuinely new content; preserve retired definitions/history. Add canonical passage and reviewed word/clue evidence, validate every answer against bundled text, verify a connected crossword fit if applicable, and register its route/family. Reuse completeActivity exactly once per completed activity and keep replay seed/difficulty out of reward identity. A new family owns its transient controller and correctness validator; it must not create a second reward writer or treat opening a card as progress. Extend tests before broadening the authored library.

Stop after Pass 6; Pass 7 is not authorized.
