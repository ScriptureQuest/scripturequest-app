# Pass 2 — Connected Scripture experience

Base: Pass 1 `42938baf93a194105baad076bb9c05ff1fdbaac3` on `v2/reading-design`.
Scope: Today, daily/weekly cross-progress, three existing Journeys, one completion summary, Journey Board, one Codex proof, connected personal destinations. No Pass 3 implementation.

## Observable behavior

- Five destinations: Today, Journeys, Bible, Learn, You. Existing profile, games, plans, achievements, collections, saved passages, and journal routes remain accessible.
- Today shows level, XP toward the next level, lifetime XP, Daily/Weekly counts, current Journey, explicit Daily and Weekly quest cards/rewards, and optional response/evening activities. Completed current-period Daily Quests remain visible. Journeys can be resumed without overdue penalties.
- Newly generated Daily and Weekly sets each reuse one existing reading slot as a flexible chapter goal. That slot retains its original XP and target count. Saved tasks are not migrated or reworded; their existing terms/rewards remain. A qualified unique chapter can advance several legitimately matching goals, each once. Quizzes no longer impersonate Bible reading or a written reflection.
- Getting Started, Knowing Jesus, and Psalms of Peace retain their original IDs, passages, order, task mapping, and history. An editorial presentation adds a purpose and passage orientation. Full-chapter reading supplies verse context. A user can revisit any passage without enrollment; only eligible active steps advance.
- Reflection steps may be explicitly passed with no reflection/step XP. `skippedStepIds` records this separately while preserving existing completed-step indices. Journey completion rewards stay as defined. Saving a reflection still uses the existing journal and reward path, with a linked passage.
- Reading Plans retain their separate schedule/enrollment system, reachable from Journeys and Today. The corrected NT90 and legacy 87-step enrollments are untouched.
- Reader completion reports actual saved XP/level changes, affected Daily/Weekly goals, Journey advancement, completed plan steps, new achievements/collection additions, and the discovery when earned. Related legacy reward overlays are suppressed during that operation. A next-Journey destination, optional linked reflection, and keep-reading action are provided.
- Journey Board shows begun/completed Journeys and dates, including existing historical completion. Revisit does not erase history or pay the completion reward again. You preserves first-class Journey Board, Codex and achievements, alongside journal/bookmarks/highlights/history/settings.
- Qualified Psalm 23 reading, freely or within a Journey, adds The Shepherd’s Care permanently to Codex. Its record includes date, passage, and earning context. The guide follows images in Psalm 23:1–6, explicitly labels commentary, links back to Scripture and toward Psalm 46/Psalms of Peace. Content is readable before earning; the permanent record recognizes exploration and does not gate the Bible.

## Integrity safeguards and directly related repairs

- Chapter, task claim, XP values, multiple-level processing, journal protections, streak thresholds, Bible data, and NT plan indices from Pass 1 are retained.
- Journey transitions are serialized. Step XP/counters and final balance rewards have stable receipts. A pending transition record permits retry after an interrupted save; opening/focusing a Journey or completing another reading resumes it. Completed legacy steps without a pending record are not retroactively rewarded.
- Completed Journey enrollment returns existing history rather than creating an ambiguous second enrollment. Completed entries are excluded from the active focus cache. Replay/revisit is available, without another reward cycle.
- Unreadable Journey history is preserved and blocks mutations rather than being sanitized into an empty save. There is no new whole-profile transaction system or multi-tab synchronization guarantee.
- Bible display/ref normalization now accepts both Psalms and Psalm. The old reference-only lookup returned an empty display name for Psalms, blocking chapter validation and the discovery loop.
- John 3 reader uses BibleRedLetterHelper's exact-text speech spans. Tests inspect actual VersesScreen RichText: Nicodemus in 3:4 and 3:9 has body color; Jesus in 3:3, 3:5 and 3:10 retains speech color. There was no remaining source defect in these speech boundaries to repair. This does not establish which revision was running in an earlier Codespaces preview.

## Validation and limits

Final validation: 39 tests pass, including the original 28. Static analysis has zero errors and exactly the same 98 warnings/26 infos as the Pass 1 baseline. Flutter Web release compilation succeeds with the icon-tree-shaking accommodation below. Tests exercise production providers/services, complete curated Journeys, replay/concurrency, persistence, qualified/free reading, optional steps, interrupted transitions, malformed history, and actual rendered reader colors and layouts. Visual test fixtures use the existing Inter/Lora fonts offline.

The cloud browser refused this workspace's local preview address (`ERR_BLOCKED_BY_CLIENT`); no claim of a cloud-browser click-through or inspection of Zeb's authenticated Codespace is made. Flutter-rendered phone/desktop screenshots and widget assertions cover available visual validation. Codespaces hands-on review and native iPhone/VoiceOver validation remain necessary. No preview infrastructure migration was attempted.

Web validation uses Flutter 3.32.8 and `flutter build web --no-pub --no-tree-shake-icons`. Disabling icon tree shaking accommodates the workspace's mismatched cached ConstFinder tool; it does not change app behavior or dependencies. Codespaces may use its established normal web-server preview command.

## Focused acceptance walkthrough

1. Open Today: confirm visible XP/level, Daily and Weekly counts, and quest rewards.
2. Journeys → Psalms of Peace → Begin → read Psalm 4 in context. Stay in the reader for at least 45 seconds and explicitly complete the chapter.
3. Inspect one result: chapter XP, the Journey step, and eligible Daily/Weekly progress. Previously saved targeted quests may legitimately not match; new flexible sets apply at their normal refresh.
4. Complete again: no replayed chapter/task/Journey rewards. Return to the next Journey step.
5. Read Psalm 23 and complete after the threshold. Open The Shepherd’s Care from the result, inspect its explanation, earning context, and Bible links.
6. Reload: progress and discovery remain. Complete the remaining Psalms steps (46, 91, 121); check completed history on Journey Board.
7. Try Knowing Jesus; pass an optional reflection without writing. Confirm it advances without reflection XP. Try saving a different reflection and revisit its linked passage in Journal.
8. Read freely or follow an existing Reading Plan. Eligible quests still progress; existing plan enrollment remains distinct.
9. With red letters enabled, inspect John 3:4 and 3:9 (normal), and Jesus' speech in 3:3, 3:5, 3:10 (red speech only).

## Intentionally deferred

Pass 3 art/themes, a larger Codex library, new games/learning mechanics, expanded memorization, full personal-history integration, broad quest taxonomy cleanup, and social/avatar systems. The 19 unmatched red-letter verses remain ordinary text pending trusted-content review. Other legacy quest wording/event semantics (such as distinct-day/book meta goals) need focused future coverage; this pass does not claim every historical template or game is now correct. No progression philosophy, XP scale, fantasy/combat mechanic, or measurement of spiritual worth was introduced.
