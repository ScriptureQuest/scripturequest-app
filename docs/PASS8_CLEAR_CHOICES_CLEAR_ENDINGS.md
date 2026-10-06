# Pass 8 — Clear Choices, Clear Endings

Completed 2026-10-06 on `v2/reading-design`, directly above the fetched and checked-out Pass 7 commit `8c4fb33926c9471c58cc52e982a833eab47bc62e`. The original StorageService startup repair `12d8b0379e013966e3ab5501a3ff3e85ca5a75bb` remains in ancestry and unchanged. Pass 7 was not recreated.

## Product decision

Make Scripture itself the depth; make the interface easier to follow. Pass 7's connected systems were useful, but passage Learn exposed several equally weighted choices and result screens could immediately recommend another unfinished activity. Pass 8 changes presentation and contextual guidance, not the amount of Scripture, authored questions, evidence work, memory practice or progression economy.

The default passage view now offers one optional way to look closer. A deliberate **Explore this passage** opens all its existing activities, connections, discoveries, remembering and related Journeys. **Browse all learning** opens the broader library; it starts open when no passage is available. Depth remains reachable without treating every available item as an obligation.

After reading, one optional passage follow-up can still be recommended. After learning, the optional continuation is passage exploration rather than the next unfinished activity. Pending completion delivery remains actionable and takes precedence. There is no sequence requirement and no new study-completion score.

## Changes by surface

| Surface | Default emphasis | Depth preserved through |
| --- | --- | --- |
| Today | Existing principal Scripture action, with more prominent action text | Existing Daily/Weekly and optional-activity disclosures; counts stay in their headers |
| Passage Learn | Current passage and one optional recommendation | Explore this passage; its connections, remembering and Journey groups; Browse all learning |
| Reading result | Actual saved passage, XP/level outcome, Done for now | One optional follow-up; Explore more; Saved progress details |
| Chapter Learning | Existing default mode and actual question count | Change question count retains Quick/Standard/Deep; original questions and grading |
| Chapter Learning result | Saved outcome, factual score, optional/ungraded reflection distinction, Done | Explore more contains replay and Scripture links; full saved receipt remains available |
| Find It in the Passage | Read the chapter and choose its evidence | Original chapter and clue; success puts the actual matching verse before reward feedback and ending |
| Word Search / Crossword | Existing passage source, puzzle and progress | Unchanged engines/input/clues; result replay, memory and navigation in Explore more; hint receipt in saved details |
| Classic game results | Saved result and Done | Shared optional exploration/replay; reference-free Book Order does not invent a passage return marker |
| Remember Scripture | Practice/recall controls and honest saved outcome | About practice and recall; after saving, Done plus context/library links and full receipt |
| Codex discovery detail | Scripture, guide explanation and source/earning condition | Explore this discovery groups evidence, memory, connections, Journeys and Board links |
| Journey detail | Current step's Scripture action | Existing outline; Along this Journey groups discovery, journal, Board and finished-Journey guidance |
| Bible Reader | Scripture and existing completion controls | Concise qualification status plus How reading progress is saved; exact 12/45-second explanation retained |

Today no longer repeats daily/weekly counts as chips or repeats lifetime XP beside current-level progress. Lifetime XP remains on You. Journal creation/editing, reflection saving and optional Journey responses retain their existing behavior. Related Journeys remain explicitly optional and do not replace a locally studied passage.

## Architecture and protected boundaries

- New `lib/widgets/sessions/session_ending.dart` owns presentation of a stopping control, one optional continuation and disclosure. `SavedDetails` keeps complete receipts reachable. It has no reward/completion writer.
- `lib/services/continuity/next_action.dart` adds explicit `readingResult` and `learningResult` contexts. Today resumes a chosen Journey/plan/reading intention before optional catalog work. Existing default resolver compatibility is retained. Local passage contexts preserve the supplied passage.
- `lib/services/sessions/passage_learning.dart` changes available-status copy to **Available · optional**; catalog/state projection remains read-only.
- Existing `DoneForNow` becomes a filled button. It still delegates to the unchanged `SessionReturn.save`, preserves malformed bytes, displays save failures and returns to Today only on success.
- Existing results/screens consume the shared presentation. Puzzle generation, selection, keyboard handling, grid geometry and completion delivery are unchanged.
- **AppProvider: 6,155 → 6,155 lines, zero changes.** No decomposition, new data model or new persistence.

Unchanged: StorageService and readiness repair; reading presence/lifecycle and thresholds; SessionReturn schema and writer; XP/reward receipts and idempotency; quest/achievement rules; activity history/delivery; Scripture and all red-letter data; authored catalog/content; Journey identifiers/enrollment/progression/history; journal/bookmarks/highlights/reading history; profile/settings/theme persistence. No migration or reset is introduced.

The only intentional guidance changes are what a screen recommends and how optional/replay state is worded. An activity still does not count as Scripture reading or independent recall. Evidence, quiz, puzzle and memory saved receipts remain authoritative; disclosures do not create rewards. A same-day stopping point still offers an optional revisit. No optional activity debt is implied on return.

## Validation

- Full regression: **107 tests pass**, retaining all 98 previous cases plus eight new logic cases and one continuous UI scenario. Existing tests are adapted to open disclosures before their original saved-content/navigation assertions; behavioral protections are retained.
- New logic coverage: Today versus passage guidance; selected plan; same-day/next-day stopping; reading versus learning results; completed/replayed study; pending delivery priority; exhausted supported passages with all catalog routes retained; unsupported passages without invented content.
- New UI scenario: **48 screen/theme/width views**, eight screens at 320/768/1280 pixels in Scripture Light and Dark, with 1.5 text scale at 320 pixels. Additional tasks exercise passage disclosure, connections, memory and related Journeys, broader browsing, real chapter-learning completion/replay, memory stopping/navigation, corrupt-marker failure/retry, failed memory saving without overwriting bytes, pending puzzle delivery and saved hint details, reference-free classic-game stopping/replay, and a catalog route into a real word search.
- Actual word-search cells are checked for at least 44-pixel targets; crossword input is focused and entered using Flutter's test keyboard. Disclosure semantics and hit-testable interaction are checked. Prior Pass 6 real puzzle completion/replay and Pass 7 reader lifecycle/startup tests remain passing. The older completion-sheet case also checks 320-pixel layout with 1.8 text scale and reachable hidden details.
- Renders inspected directly include guided Learn, enlarged-text phone Learn and reading result, large Today, and phone crossword in both themes. Automated views use actual app widgets and navigation in a test harness; they are not independent human usability studies.
- `flutter analyze --no-pub`: **zero errors, 92 existing warnings, 26 existing infos**. All 118 diagnostic identities match the fetched Pass 7 baseline, ignoring line/column movement.
- Production `flutter build web --release --no-pub --no-tree-shake-icons`: succeeds with the existing cache/icon accommodation.
- Full diff and whitespace review; protected service/data files unchanged. Existing preview configuration and build/transfer artifacts excluded from the commit.
- Live browser attempt against the built local app was blocked with `net::ERR_BLOCKED_BY_CLIENT`. Live Codespaces/native-device, VoiceOver/TalkBack, actual soft-keyboard occlusion and release qualification are **not claimed**. No browser/security restriction was bypassed.

## Acceptance walkthrough for review

1. Open Today: one reading intention should dominate; quest headers retain progress and expand to the same goals.
2. Open Learn for John 3 with an unrelated active Journey: keep John 3 primary; see one optional recommendation. Open Explore this passage to find every existing passage opportunity, then Browse all learning for the full library.
3. Finish reading: actual saved outcome precedes Done. Inspect saved details for achievements/discoveries and full changes. Keep reading/reflection/library links remain under Explore more.
4. Finish evidence: see the matching Scripture verse before the ending. Finish quiz or puzzle: stop successfully or choose optional passage exploration; another unfinished activity is not demanded.
5. Replay: earlier rewards remain kept; gameplay/learning remains available. Pending delivery exposes Retry before any successful-ending claim.
6. Save memory practice, assisted recall or independent recall: truthful outcomes remain distinct. Done saves the same kind of return point and returns to Today. Failure does not fabricate completion or overwrite unreadable data.
7. Expand related Journeys and discovery links: routes and optional reflection remain accessible without becoming the primary passage action.
8. Check Light/Dark, small and large widths and larger text. Continue substantial reading and deeper study through the disclosures; no Scripture has been shortened.

## Risks, findings and deferred work

Progressive disclosure adds an intentional step to optional depth. Discoverability still needs user acceptance in the existing Codespace and on phones; the automated checks demonstrate reachability, not proven reduced cognitive load for every user. Default recommendation order is deterministic and content-backed, not a new personalized study engine.

No new blocking data-integrity defect was discovered. Existing notification-plugin fixture warnings, legacy weekly-title range and Bible fallback logs remain recorded rather than reclassified as harmless production behavior. Static-analysis debt remains at its prior baseline. Comprehensive integrity/backup review and native accessibility qualification are separate work.

Deferred: new games, larger crossword/word-search libraries, Journey/content expansion, new onboarding, scheduled memory review, unfinished-board resume, provider/storage/router decomposition, backup/restore, native release work and the **19 unmatched red-letter verses requiring trusted review**. No guessed theology/content was added. **Stop after Pass 8; no Pass 9.**

The handoff reports the exact commit and verified full-history transfer separately. This document cannot contain its own commit hash. Historical Roadmap/Recovery entries remain intact; their earlier authorization boundaries describe their respective handoffs.
