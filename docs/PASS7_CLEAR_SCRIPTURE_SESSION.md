# Pass 7 — A Clear Scripture Session

Completed 2026-10-04 on `v2/reading-design`, directly above Pass 6 `02bfdc6a9df6855772fa1d213db0a1605f4860aa`. The ancestry includes the original StorageService startup repair `12d8b0379e013966e3ab5501a3ff3e85ca5a75bb`. That service and its regression protections are unchanged.

## Product decisions and experience

Today now puts one principal Scripture action above progression and collapsible Daily/Weekly goals. Existing quests remain usable rather than competing with the principal action. Journey progress, journal and personal-library surfaces remain available. Guidance uses the user's active Journey on Today; explicit free-reading and passage-learning contexts keep the current passage primary even when an unrelated Journey exists.

Learn receives `/learn?ref=...` and presents the current/recent passage first. It projects existing chapter learning, evidence activities, puzzles, Connections, Codex discoveries, remembering choices and related Journeys. All five existing chapter quizzes are exposed, without inventing content. Available work, pending delivery, completed optional replay and optional exploration are distinct. Unsupported passages honestly offer reading/exploration rather than manufactured learning material. The broader library remains accessible below the passage panel and can use a wider desktop surface.

Reading, quiz, evidence, puzzle and classic-game results connect to the same contextual guidance. Saved outcomes remain visible. Activity completion explicitly does not claim reading or independent recall; reflection remains optional/ungraded. Evidence success shows the matching verse and retains the full-passage link. A shared Done for Now saves a return point and returns to Today. Today's same-day return is an optional revisit; tomorrow's guidance can resume normal progression. This is a stopping choice, not another receipt or completion metric.

Journey details promote the current step and move the rest into an expandable outline. All original passages, step IDs, rewards, optional responses, enrollment and history remain. Codex is labeled “Codex — Discoveries.” The unreachable learning-games milestone explains future library availability while preserving already-earned achievements and historical counts.

## Architecture and changed files

- `lib/services/sessions/passage_learning.dart`: read-only catalog/state projection and honest opportunity states.
- `lib/services/sessions/session_return.dart`: additive per-user stopping marker; validates existing bytes before writing.
- `lib/services/reading/reading_presence.dart`: injectable monotonic clock for visible foreground chapter presence; no progression writer.
- `lib/services/continuity/{next_action,continuity_reader}.dart`: explicit session contexts, quiz/activity/pending/return-state inputs, deterministic recommendations. Existing default resolver semantics remain for compatibility; product surfaces opt into explicit context.
- `lib/widgets/sessions/`: primary Today action, passage panel, stopping control, startup gate.
- `lib/widgets/connected/{next_action_panel,reading_result_sheet}.dart` and `lib/widgets/common/game_end_panel.dart`: shared follow-up and truthful saved results.
- `lib/screens/{quest_hub_screen,verses_screen,chapter_quiz_screen,achievements_screen}.dart`, `lib/screens/connected/{exploration_screen,journeys_screen}.dart`, `lib/screens/activities/activity_screen.dart`: scoped product integration and responsive interactions.
- `lib/data/connected/connected_catalog.dart`: exposes existing chapter learning from the existing quiz source.
- `lib/main.dart`: startup gating/retry and Learn passage query; existing router preserved.
- `lib/providers/app_provider.dart`: serialized initialization attempt, recorded loading/error state, safe retry without reassigning initialized late services, read-only return marker and library capacity facade. Physical line count 6,093 → 6,155 (+62); no giant decomposition or new game/session engine inside the provider.

## Startup and reading findings

Reproduced: a covered reader continued accruing elapsed time; the pre-fix real-widget regression failed with approximately 180 ms of hidden time. ReadingPresence now pauses while covered/backgrounded and resets for a changed chapter. A mounted chapter resumes its accumulated active time; leaving/disposal or restart does not persist reading time. Only the selected chapter's loaded verse content counts; prefetched pages and loading/error text do not qualify. Existing 12-second presence and 45-second qualified-completion thresholds and authoritative reward writers are retained. Qualified, unqualified and repeated completion are covered. This fixes the demonstrated lifecycle fault, not a claim that every previously reported native timer issue has been reproduced.

Reproduced with fixtures: malformed profile startup blocks usable content and provides Retry; concurrent attempts share one completion/error. Existing bytes remain intact. Retry reloads saved data through the original StorageService readiness contract. It cannot repair corrupt data automatically; support/recovery guidance is shown and no reset is offered.

Pending puzzle delivery now has a visible retry path reconstructing only an already accepted completion with its saved best-hint value. No unfinished board is represented as completed. Existing idempotent delivery and receipts remain authoritative.

No new cold-storage singleton race was found or recreated. No native-device report was independently reproduced here. Notifications plugin warnings in widget fixtures and legacy weekly-title range / Bible-passage fallback logs were observed; broader diagnosis is deferred because scoped acceptance passed. They are not certified as harmless production behavior.

## Data and progression preservation

Only new persistence: `session_return_v1_<user id>` containing canonical reference and stopping timestamp. Malformed existing marker bytes are preserved, not replaced. There is no migration, reset, XP economy change, new reward service, or change to Scripture/red-letter data. Existing Journey/quest, activity/quiz/discovery, journal/bookmark/highlight/history, memory, profile/theme and receipt regression tests remain. Reading still requires explicit qualified completion; playing/learning does not substitute for reading. Replays and pending delivery keep earlier rewards.

## Validation

- Full final regression: **98 tests passed**, all 85 prior cases plus 12 new logic/integrity tests and one continuous UI scenario.
- New coverage: six user-session contexts; unrelated active Journey; all five quizzes/unsupported passage; completion/pending/replay guidance; stopping/restart/next-day; malformed marker and startup/concurrent retry; lifecycle/chapter timing; unqualified/qualified/repeated reading; pending delivery; nonmutating catalog projection and historical capacity.
- UI scenario: **28 screen/theme/size views**, Scripture Light and Dark, 320-pixel phones at 1.5 text scale and 1280-pixel layouts. Includes Today, passage Learn, Journey, reading result, crossword and word search. Real route cover/return, background/resume, passage query navigation, pending Retry and a real modal Done for Now are exercised. Renders were inspected.
- Existing Pass 6 actual crossword keyboard entry, word-search interaction and replay tests pass. Existing Pass 3 helper now centers targets and asserts hit-testability before tapping; no behavioral assertions removed. Two Pass 6 title expectations changed to the more accurate “Activity completed”; completion and reward assertions retained.
- `flutter analyze --no-pub`: **0 errors, 92 existing warnings, 26 existing infos**. All 118 diagnostic identities match the Pass 6 baseline (ignoring line/column movement).
- Production `flutter build web --release --no-pub --no-tree-shake-icons`: succeeds with the existing cache/icon accommodation.
- Diff whitespace check passes; original StorageService, reward-service and Scripture files unchanged. Preview configuration and transfer/build artifacts excluded from the commit.
- Automated Flutter widgets and production Web compilation are verified. Live local-browser access was blocked; live Codespaces, iPhone/Android, VoiceOver/TalkBack, native keyboard and native release acceptance are **not claimed**.

## Acceptance walkthrough

1. Open Today: follow the single principal action; expand quests to inspect all existing goals.
2. With a John Journey enrolled, read Romans 8 freely: result and Learn continue Romans 8; related Journey return stays secondary.
3. Complete evidence/quiz/puzzle: inspect truthful saved outcome; reopen passage Learn and distinguish completed optional replay from new work.
4. Choose Done for Now: Today offers an optional saved revisit. Restart retains it; a new local day restores normal guidance.
5. Cover the reader, background/resume, or change chapters: hidden time must not qualify; explicit completion after active presence uses the original writer.
6. Simulate an unreadable startup fixture: Retry is visible and no saved data is cleared. Restore valid bytes through a supported recovery process before expecting Retry to succeed.
7. Inspect both themes and narrow/large layouts, including large text, crossword input focus and horizontal-grid scrollbar.

## Limitations and deferred work

Stop after Pass 7. Backup/restore, comprehensive bug hunt, full AppProvider/storage/router decomposition, onboarding expansion, scheduled memory review, new games/Journeys/large content libraries, native release qualification, unfinished-board resume and universal legacy-game/content audits remain deferred. The 19 unmatched red-letter verses still require trusted review. No speculative Scripture or theology was added. Completion status is evidence of activity, not a claim of understanding. More native/accessibility/performance validation is required before release.

The handoff reports the exact commit hash and verified full-history bundle separately; a commit cannot contain its own final hash. Historical roadmap/recovery records remain intact.
