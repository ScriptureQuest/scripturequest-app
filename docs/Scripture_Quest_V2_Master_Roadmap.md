# Scripture Quest V2 Master Product & Development Roadmap

September 12, 2026 • Approved authoritative living roadmap • Pass 1 implementation review

## 1. Product commitment

**Scripture Quest makes engaging with Scripture an enjoyable, lasting practice through guided quests, learning, reflection, discovery, and meaningful progression.**

Peaceful is the emotional tone; gamification is part of the product. V2 must not become a plain Bible reader with the interesting parts hidden. Reading should drive quests, journeys, XP, achievements, learning activities and discoveries. Progress should celebrate participation and understanding without claiming to measure someone’s faith or standing with God.

The core loop is:

**Choose today’s reading or continue a journey → read → optionally reflect or practice → receive accurate progress and rewards → see what you accomplished and what comes next.**

Free reading remains unrestricted. Games support learning; reflection is never graded. No fantasy combat, magical equipment, spiritual power scores, paid Scripture access, or punishment for being unable to maintain a streak.

## 2. Authority, evidence and current baseline

This is the proposed single planning reference for V2. Existing approved constraints remain binding; new recommendations below are proposals until approved. Old documents remain historical evidence, not competing implementation queues. Approval of a roadmap should not authorize a huge unattended rewrite: work proceeds in bounded, separately reviewable passes.

Evidence reviewed:

- Current remote `ScriptureQuest/scripturequest-app`, branch `v2/reading-design`: Git remote lookup independently confirms **6700909b56d837ca8b3f51ae113a13a2c3939622**, matching the local source inspected.
- Zeb confirms this first V2 Today/Reader pass runs successfully in Codespaces. That is owner-observed success; it is not a claim that the agent performed a complete device regression test.
- Existing Project Recovery Record, prior V2 assessment stored as “Pasted markdown.md,” repository `architecture.md`, `replit.md`, `V2_READING_PASS.md`, source and relevant Git history.
- Retrieved November 29–30, 2025 roadmap and development discussions, plus available project continuity history for later naming, deferred features and quest decisions. Not every original conversation is available verbatim. Historical recollection is not treated as proof of implementation.
- Read-only structural checks of the Bible asset, guided reading references and plan generation. No application source, dependencies or native configuration changed in this audit. No setup, preview investigation, build or new runtime test performed.

Status labels used below:

- **OWNER-TESTED:** Zeb reports the application/preview works. Feature-specific exhaustive testing is not implied.
- **SOURCE-VERIFIED:** code/content exists or a condition is demonstrable from it.
- **DEFECT:** a specific contradictory or unsafe code/data path is established; runtime reproduction may still be pending.
- **RISK / UNVERIFIED:** a scenario needs a real test; not a reproduced bug.
- **HISTORICAL PLAN:** recorded direction or continuity history, not necessarily implemented or freshly approved.
- **PROPOSED:** Astra’s recommendation for review.

## 3. Reconcile the development history

| Earlier direction | Evidence/status today | V2 disposition |
|---|---|---|
| Original FaithQuest roadmap: Bible, XP/levels, achievements, streaks, reflections and quest board first | Retrieved November roadmap; substantial source exists | Preserve the foundation and earned history |
| Later memorization, automatic quest hooks, titles and enhanced achievements | Many related screens/hooks exist | Repair and connect before adding parallel systems |
| Campaigns, biblical artifacts, events, highlights and plans | Plans, guided quests, artifact/mastery code and highlights already exist | Improve existing content and discovery; do not describe these as wholly new features |
| Avatar/gear-centered loop, inventory first, neon RPG aesthetic | Earlier assistant recommendations; later avatar/equip and purchases disabled | Preserve useful collections/data; do not restore equipment or neon UI merely because an early roadmap mentioned it |
| Tasks = one-off activities; Quests = multi-step; Collection → Codex; Leaderboard → Journey Board | Naming decisions in continuity history; code remains inconsistent | Adopt a glossary below; change user-facing terminology deliberately without renaming storage/models wholesale |
| Five-tab earlier layouts with Bible central | Historical layouts, not current architecture | Current three-tab V2 remains until navigation pass; proposed final five-tab structure restores Bible central without restoring unfinished Avatar/Community tabs |
| Nightly window 8 PM–2:59 AM | Historical requirement; current Hub switches at 6 PM/6 AM and services use calendar dates | Reconcile explicitly in behavior pass; do not silently claim current behavior matches the old requirement |
| January Quest System v1: 20 XP anchor, recommended-reading bonus, 15 XP side task, anti-repeat rules | Continuity history describes it, but named feature flag and exact system not found in this checkout; TaskService/board systems coexist | Carry forward as intended-design evidence. Trace before selecting reward amounts; do not invent a missing implementation or overwrite current balances |
| Always Free Core; cosmetics optional later; single-player MVP | Historical product constraint; core local app and disabled purchases fit that direction | Preserve free core and single-player usefulness. Social/cloud and monetization remain separate decisions |
| First V2 calm Today + Bible Reader | Committed, remote verified and owner-tested | Preserve; add visible progression back into hierarchy where needed rather than undoing the visual foundation |
| Earlier V2 suggestion to hide most progress and remove Profile as a primary destination | Assistant proposal, not a binding requirement | Rethink in light of explicit owner direction: accomplishments deserve a first-class home |

`architecture.md` describes an early sample-data/neon design and labels many tasks complete. Those checkmarks do not establish present quality. `replit.md` has useful history but its claims about tests are not a substitute for tests of the current actual screens.

## 4. Proposed final product structure

Recommended bottom navigation: **Today • Journeys • Bible • Learn • You**. Bible remains central. Use readable labels and test five targets on small phones with enlarged text; do not force this through if it fails accessibility checks.

| Destination | Responsibility | Important contents |
|---|---|---|
| Today | Answer “What should I do today?” | Primary reading, active journey continuation, daily/weekly tasks, concise XP/level progress, completion state, reflection shortcut, secondary daily verse |
| Journeys | Choose and continue structured Scripture engagement | Guided Quests and Reading Plans, clearly labeled by format; purpose, passage, duration, steps and earned milestones |
| Bible | Read freely and find passages | Offline KJV, chapter/passage selector, reader settings, verse tools and saved-passage access |
| Learn | Enjoy and remember Scripture | Memorization, chapter quizzes, Matching, Verse Scramble, Book Order and optional Emoji Parables; suggested practice connected to recent reading |
| You | See a personal history worth keeping | Level/XP, achievements, Journey Board, Codex, book progress, journal, saved passages and settings |

Journal stays easy to reach from Today, verse actions and You; it should not require hunting through settings. Within saved content, distinguish bookmarks (return points), highlights (marked text), favorites (chosen verses) and reflections, while presenting one coherent entry point. Preserve separate existing records initially.

Proposed glossary: **Tasks** are daily/weekly/single activities; **Guided Quests** are multi-step experiences; **Reading Plans** are schedules; **Journeys** is their shared discovery destination; **Journey Board** is personal accomplishment history; **Codex** is learned discoveries and biblical keepsakes. Avoid exposing Questline/TaskModel/internal names to users. “Quest Hub” remains the product concept behind Today.

### Today hierarchy and progression

1. Greeting, readable level/XP progress and supporting streak/rhythm status—not an enormous dashboard, but not invisible.
2. One clear primary reading. An active guided journey can supply it; otherwise the existing daily reading task or genuine continuation. Resolve how that reading counts toward the daily task before implementation.
3. Current journey step and understandable progress, for example “2 of 5 steps.”
4. One optional response: reflect, save, memorize or answer a passage-related question.
5. Daily/weekly tasks and a small “next accomplishment” preview; optional exploration below.
6. Completion transforms the screen: what counted, XP earned, journey progress, any achievement/discovery, and “Done for today” or “Keep exploring.”

Do not conceal earned rewards inside a permanently collapsed section. Do not present five equally important starting actions.

## 5. Inventory: preserve, repair, develop or defer

| Feature | Current evidence/status | Roadmap treatment |
|---|---|---|
| Today + Reader V2 | OWNER-TESTED overall; SOURCE-VERIFIED presentation | Preserve, regression-test, repair known edge cases |
| Offline Bible | SOURCE-VERIFIED 66 books / 1,189 chapters / 31,102 verses; numbering/empty checks pass | Preserve; certify textual provenance and correctness separately |
| Reader fonts, themes, sizing, verse tools | SOURCE-VERIFIED; primary preview works | Preserve and audit across routes, settings and devices |
| Daily/nightly/weekly/reflection tasks | SOURCE-VERIFIED generation, persistence and automatic hooks | Keep; resolve multiple completion/reward paths and time rules |
| XP, levels, streaks, achievements | SOURCE-VERIFIED substantial implementation with defects below | Central identity; repair before more economy/content |
| Guided Quests | Nine definitions: Getting Started; Journey through John; Peace in the Storm; Knowing Jesus; Psalms of Peace; Teachings of Jesus; Genesis Beginnings; Proverbs for Wisdom; Life of David | Improve editorial depth and prove every step is completable; do not replace with an invented catalogue |
| Reading Plans | Seven seeds including Journey Through John, Psalms of Comfort, Wisdom for Life, Story of Jesus highlights, Gospels/30, Proverbs/31, NT/90 | Preserve, validate duration and completion semantics, clarify overlap with guided quests |
| Journal | SOURCE-VERIFIED search/tags/pins/edit/storage; corruption risk below | Preserve personal entries; reliability and backup before encouraging long-term dependence |
| Bookmarks, highlights, favorites | SOURCE-VERIFIED separate records and tools | Preserve; consistent access, identifiers and return positions |
| Memorization | SOURCE-VERIFIED screens and practice hooks | Improve review scheduling and connection to actual saved passages; prove completion/reward behavior |
| Learning games | SOURCE-VERIFIED Matching, Scramble, Book Order, Emoji Parables | Preserve; correct content and improve learning value, not just tap speed |
| Chapter quizzes | Five authored chapter sets, not universal coverage | Honest availability; verify answers before expanding |
| Codex, artifacts, book mastery, titles | SOURCE-VERIFIED models/seeds/reward hooks and partial UI | Retain meaningful discovery; interpret artifacts as educational keepsakes, not magic/stat equipment |
| Avatar/equipment and cosmetics | Intentionally disabled/deferred surfaces; inventory includes placeholders | Keep stored work; exclude from release-critical navigation and do not imply purchases work |
| Community, friends, prayer wall, global competition | Historical plans; partial/local/coming-soon surfaces, not a proven social backend | Defer online promises; never present seeded bots as real people |
| Family mode, seasonal campaigns, audio, another translation | Historical/new opportunities; capabilities differ by feature | Later scoped decisions after core reliability and content; no prerequisite for single-player V2 |
| Backup/restore | No complete user-facing recovery flow established in inspected code | Proposed release priority, before cloud accounts; preserve local-first design |

## 6. Systematic quality audit

The findings below distinguish source-level defects from acceptance tests still needed. An app opening successfully does not resolve them.

| ID / priority | Finding and evidence | User impact / required proof |
|---|---|---|
| Q01 / release blocker | **DEFECT: red letters are inaccurate.** `BibleRedLetterHelper` marks whole broad ranges. Matthew 7:28–29 narration, John 3:4 Nicodemus, and John 11:35 narration are marked red. John 16:1 is omitted; Acts coverage stops at chapter 1. Both reader and global rendering apply one style to whole verses. | Correct at speech-span level using reviewed, edition-aware annotation. Broad range tweaks cannot correctly handle mixed-speaker verses. Until corrected, do not advertise current toggle as accurate. Preserve underlying Bible text; no AI-invented speech boundaries. |
| Q02 / release blocker | **STRUCTURE PASS, TEXT UNVERIFIED:** Bible asset has 66 unique book records, 1,189 chapters and 31,102 nonempty verses; chapter/verse sequences and canonical chapter counts match. No full trusted-edition textual diff/provenance certification performed. | Pin a trusted source/edition and checksum, compare text, document punctuation/normalization decisions; verify beginning/end and difficult passage rendering. Counts alone are not certification. |
| Q03 / high | **DEFECT: inconsistent learning text.** Scramble asset John 3:16 uses “one and only Son,” unlike bundled KJV “only begotten Son”; other game snippets also differ. Scramble loads its six-entry asset; Matching has an eight-entry fallback pool. | Use verified KJV text or explicitly labeled excerpts/paraphrases with provenance. Do not teach mixed text as exact KJV memorization. Validate references and quiz answers. |
| Q04 / release blocker | **SOURCE-CONFIRMED repeat-reward path.** Reader completion remains available after completion and emits `chapterCompleted` each time. ProgressEngine increments its chapter counter and adds 10 XP without an event deduplication check. Provider’s unique chapter set does not guard that separate event. | Test repeated tap, reopen, rapid double tap and interrupted save. Award once per defined qualifying completion; legitimate rereading needs an explicit repeat policy. Distinguish unique chapters from reading sessions. |
| Q05 / release blocker | **DEFECT / replay risk:** Task reward claim calls `completeQuest` again. That method also runs mastery, loot and questline side effects; its persistent-task reward branch lacks a central claimed-state check. UI guards exist but are not an atomic transaction. | Verify completion → claim → restart, simultaneous claims and failed writes. One completion must not replay unrelated progress or random reward attempts. |
| Q06 / high | **DEFECT:** ProgressEngine directly unlocks `quiet_reflections_5` and `night_scholar_5` on individual corresponding events. `unlockIfNeeded` checks existing unlock, not requirement count. Other provider paths do count, creating disagreement. | At four qualifying actions remain locked; fifth unlocks once; reload retains exact state and reward. Verify every achievement trigger and advertised requirement. |
| Q07 / high | **DEFECT for large grants:** UserService `levelUp` advances one level per `addXP`, even if remaining XP crosses another threshold. | Large reward tests must consume all earned thresholds, preserve total XP and keep progress display valid; no balance changes needed. |
| Q08 / high | **Inconsistent completion contract:** chapter completion uses 12-second presence plus engagement, reading tasks/streak use 45 seconds. Weekly board progress also requires a never-before-read chapter. Completing too early marks it read; rereading later may no longer qualify for that weekly branch. | Test first read at 12–44 seconds then qualified reread, wrong book/chapter, prior lifetime reads, and multi-chapter tasks. Agree on “read,” “qualified reading,” and “task complete”; every message must reflect what actually counted. |
| Q09 / high | **RISK:** reader uses elapsed wall-clock time; no lifecycle observer was found to pause on backgrounding. Timer starts once per reader state. | Background app/browser, open a sheet, change chapter, resume. Define and verify active-reading timing rather than assuming wall-clock presence means engagement. |
| Q10 / high | **RISK / known mismatch:** Bible streak and UserService streak coexist. Calendar-midnight difference uses `.inDays`, which merits DST/timezone testing. Hub shows Tonight after 6 PM, unlike historical 8 PM–2:59 AM. | One authoritative displayed streak; tests for midnight, DST, missed days, time travel, timezone change, and one reward per day. Confirm intended nightly schedule before altering it. |
| Q11 / release blocker | **DEFECT: destructive corruption path.** JournalService’s user-facing load skips malformed entries, but mutation loader `_getAllEntries` returns an empty list if any decode fails. A subsequent add can overwrite the stored list. UserService may create/save a replacement user after decode failure. | Preserve recoverable raw data; no silent resets. Inject malformed entries and prove valid entries remain after add/edit. Offer recoverable backup/restore; test interrupted writes. |
| Q12 / high | **RISK:** StorageService swallows save errors and ignores returned success booleans; journal reads/writes a whole list with no serialized transaction. | Simulate failed save and overlapping edits; do not show “saved” when persistence failed. Export/import must preserve IDs, dates, references and progress without destructive replacement. |
| Q13 / high | **CONTENT DEFECT:** “New Testament in 90 Days” generates 87 steps (260 chapters, chunks of three), not 90. Guided/plan John names imply the same journey but cover different chapters. Thirty-four literal guided reading references passed bounds checks; this does not prove all task types can finish. | Correct duration or schedule intentionally; inventory all nine guided quests, generated step mappings, memory/reflection steps, restart/abandon/re-enroll and rewards. Missing-step fallback currently creates a generic quest, masking bad content. |
| Q14 / high | **V2 regression risk:** Today counts completed tasks from filtered helper results; auto-reset tasks completed today are excluded by helpers. Completed count/denominator and “all done” can therefore be misleading for those tasks. Some quest types may fall outside action/reflection filters. | Test seeded empty, first-use, partial, completed, expired, midnight and nightly states against stored task IDs. Nothing eligible should silently disappear. |
| Q15 / high | **UNVERIFIED:** highlight/bookmark/favorite/journal references use several pathways. | Create/edit/delete and restart; check Psalm/Psalms aliases, multiword/numbered books, focused verse return, stored position, theme preferences and local user identity. Confirm independent data stays intact. |
| Q16 / high | **PARTIAL accessibility:** V2 reader applies system text scaling and has clearer controls; global `BibleRenderingService.richText` does not explicitly pass a text scaler. Custom gestures and older screens need VoiceOver/focus audit. | Test 320–430px widths, large text, landscape, keyboard, night/sepia/highlights/red-letter contrast, reduced motion, labels and logical reading order. Progress cannot depend on color alone. |
| Q17 / medium-high | **PARTIAL navigation/UI:** legacy `/home`, task/quest routes, multiple saved-content destinations and placeholder screens coexist. Profile says “Explore (Coming Soon)” over useful destinations. V2 theme is scoped to `/`, `/bible`, `/verses`; other reading routes can diverge. | Test start from task/plan/journey/game → passage → back, browser history, reload/deep links and book boundaries. Remove misleading promises from active navigation, preserve useful routes/data. |
| Q18 / high | **TEST GAP:** existing reader tests largely build stand-in widgets instead of production screens. Prior analysis zero errors proves types, not product behavior. | Add meaningful tests against actual providers/services/screens, persistence and content. Native iPhone regression remains a separate gate after web testing. |

No runtime exploit, data-loss incident, VoiceOver result or full Bible-text certification is claimed here. The concrete defective branches justify targeted repair; risk rows require tests before declaring failures or fixes.

## 7. Gamification that belongs in Scripture Quest

Preserve XP and levels as visible, reliable feedback. Add a short progress line on Today and a satisfying progress home under You. Preserve existing totals; never reset earned history to simplify V2.

Make accomplishment tangible through three connected layers:

1. **Today:** complete a reading task, optionally respond, and see a truthful XP/result summary.
2. **This journey:** visible steps, intentional practice, a meaningful ending and a preview of the next discovery.
3. **Your history:** books explored, journeys completed, verses practiced, achievements and Codex keepsakes, with the journal as personal meaning rather than a scored exercise.

Use existing book mastery and artifact work selectively. A keepsake should explain its connection to the passage and what the reader accomplished. Do not convert Scripture into loot grinding. Use descriptive milestones instead of ranks implying superior Christianity. Prefer predictable learning-related unlocks over repeated random drops.

Keep daily and weekly goals. A missed day can interrupt a streak without erasing accomplishments. The old streak-recovery quest should be reconsidered: a welcome-back path is useful; implying the user must earn back spiritual worth is not. Changing recovery rules or XP amounts requires a specific reviewed policy, not a cosmetic edit.

## 8. Prioritized development sequence

### Pass 1 — Scripture and progress integrity

**Exact next pass.** Touch red-letter annotation/rendering, Bible/game content validation, chapter/task reward handlers, achievement gates, large-XP level handling, journal corruption/save signaling, and the Today completion regression where needed. Use narrow fixes in existing services; do not replace the entire provider/storage architecture.

Resolve product contracts first: what qualifies as reading, legitimate reread rewards, intended nightly window, and recommended-passage vs free-reading task equivalence. Present only choices that cannot be recovered from history, with a recommendation.

Exit gate: approved correctness rules; verified red-letter examples and mixed-speaker cases; no duplicate event/claim rewards; five-task achievements unlock on five; large grants level correctly; early-read/later-qualified completion works as intended; corrupted journal tests preserve good entries; real production-path tests pass. No new tab structure, economy, large content catalogue, or illustrations in this pass.

### Pass 2 — Connected journeys and visible accomplishment

**Second.** Implement final navigation after approval; connect Today, Journeys, Bible and You. Keep journal one tap from Today. Make XP/level, current journey and next achievement visible. Unify completion presentation using the corrected reward result. Consolidate discovery for existing guided quests/plans without merging storage engines.

Start with three existing guided experiences: **Getting Started, Knowing Jesus, and Psalms of Peace**. Edit for clear context, coherent steps and optional response; do not invent replacement campaigns. Label the John plan/quest distinctly. Correct plan schedules. Provide honest active/completed/empty states and predictable return-to-journey behavior. Use existing icons and typography while interaction settles.

Exit gate: a new reader completes the first guided step; a returning reader resumes the right step after reload; completion grants the right rewards once; XP/history/journal remain accessible; all released journey steps are finishable; navigation passes mobile and large-text checks. Do not revive avatar/social systems.

### Pass 3 — Learning, Codex and distinctive visual assets

**Third; this is the main custom-graphics pass.** Improve Learn using existing memorization, quizzes and games, with reviewed source text, passage-linked practice and honest coverage. Develop the existing Codex/book-mastery presentation into a browsable collection of meaningful discoveries. Carry the V2 visual language through these surfaces.

Create a small consistent asset set only for content already working: three journey covers, a first family of achievement/keepsake images, and a restrained milestone animation. Add review prompts tied to saved verses; avoid claiming mastery from one lucky quiz result.

Exit gate: a user can read → practice → earn a documented accomplishment → inspect its meaning in Codex → return to Scripture. Games support replay without accidental XP farming. Images work on phone, dark mode and accessible layouts; reduced motion has a complete alternative. No shopping, fantasy inventory or social backend.

### Pass 4 — Personal ownership and release UX

Finish safe backup/restore, saved-content organization and journal polish. Shorten onboarding around a first meaningful reading, with existing reading comfort/name preferences retained and advanced choices deferred. Complete accessibility and native interaction checks across released surfaces. Hide dead promises, audit beta labels and support information, and test reminders only if included in release scope.

### Pass 5 — Release qualification

Regression-test cold start, upgrade from existing data, restore, offline use, interruptions, multi-day progression and real iPhone layouts. TestFlight build/signing validation belongs here, using the existing workflow. Confirm text/translation provenance, editorial review, accurate screenshots and descriptions, and that beta-only flags/settings are intentional. Do not infer iOS readiness from Codespaces.

### Later / explicitly optional

One-device family discussion sessions before family accounts; reviewed seasonal journeys; audio/TTS after practical testing; an additional properly sourced translation; optional cloud backup/account sync; prayer/community features only with a real operating plan. Avatar equipment, cosmetics, paid systems, global rankings, chat, guilds/multiplayer and AI spiritual-advice chat are not V2 release dependencies. Retain existing dormant work unless a separate decision removes it.

## 9. Where custom graphics earn their place

| Asset | Product job | Recommendation |
|---|---|---|
| Journey covers | Let readers recognize and return to an experience | Distinct imagery and consistent framing for three curated journeys; text remains actual UI, not baked into image |
| Codex keepsakes | Make accomplishment memorable and connect it to Scripture | Illustrated lamp, seed, scroll, landscape or other content-supported object with a reviewed explanation; never implied magical powers |
| Achievement families | Communicate category and increasing accomplishment | Consistent silhouettes, readable labels and restrained tier treatment; not hundreds of unrelated AI badges |
| Simple journey-path illustration | Show completed/current/next step | UI-driven progress indicators with optional illustrative backdrop; no huge fantasy map or pretend geographical accuracy |
| Completion motion | Make a genuinely earned moment feel satisfying | One brief reveal for a milestone, not confetti on every tap; reduced-motion version |
| Context maps/timelines | Improve biblical understanding | Later, when editorial facts are verified. Use accurate authored diagrams rather than generated factual maps |

Do not add decorative art behind Bible text, generic biblical portraits everywhere, stock gradient cards, or illustrated empty states that obscure a useful action. Preserve the teal identity; verify the existing torch artwork before adapting it. Warm paper, deep teal, readable ink, Lora/Inter and restrained gold for achievements form one system. Peaceful does not mean visually anonymous.

## 10. Definition of done and decision discipline

Every pass uses: inspect relevant implementation → preserve checkpoint → implement bounded change → test actual production paths → compile → inspect mobile behavior → revise → document → owner review. A green analyzer alone is never the finish line.

Release correctness gates: Q01–Q08 and Q11–Q13 resolved or explicitly scoped out without misleading claims; Q09–Q10 and Q14–Q18 covered by documented acceptance tests. Preserve data through upgrades. Critical text, saving and reward failures block release even if the UI looks finished.

Track one current backlog using Q IDs and pass numbers. Each change records evidence, observable expected behavior, validation and remaining limits. Keep old decisions as history; do not silently upgrade an AI suggestion to owner approval.

## 11. Current state

WORKING: owner-tested V2 Codespaces preview at baseline `6700909`; Pass 1 production-service/provider regression suite passes. Flutter/Dart and existing gamified product structure preserved.

BROKEN / OPEN: 19 red-letter source/text mismatches remain ordinary text pending trusted-content review; full KJV certification, cross-system crash atomicity and previously recorded legacy UI/progression debt remain release review items.

IN PROGRESS: Pass 1 handoff for Zeb’s testing; no Pass 2 implementation.

BLOCKED: no code-validation blocker. Native iPhone/VoiceOver and human preview validation remain unperformed for this integrity commit.

NEEDS FROM ZEB: test/review the completed Pass 1 candidate before approving the next pass.

NEXT ENGINEERING ACTION: respond to Pass 1 review findings; do not automatically begin Pass 2.

## 12. Approved guardrails and Pass 1 disposition — September 12, 2026

Zeb approved this roadmap. XP, levels, journey/daily/weekly progress, achievements and accomplishment feedback must remain visible. Journey Board and Codex remain first-class experiences. Pass 1 prioritizes Scripture, saved data and earned progress. Final custom graphics primarily belong in Pass 3. Prior approved ideas remain classified and retained; changes to this living roadmap require an explicit recorded reason.

The Q01–Q18 audit table above is the historical baseline at `6700909`; the following implementation disposition supersedes its current-status wording, not its evidence/history.

- **Q01 — repair implemented, content review remains:** sourced exact speech spans replace broad ranges. 2,009 verses mapped; all bounds, fingerprints and rendered text tested. Nineteen unmatched verses are explicitly reported and remain normal text. No Scripture asset changes or guessed corrections.
- **Q03 — identified assets repaired:** eight core and six scramble passages now exactly match bundled KJV, with answer-word checks. Other fixtures/full translation provenance retain Q02 review; this does not certify all game content.
- **Q04/Q05 — scoped replay repairs validated:** chapter award receipts and persisted task reward receipts, serialized operations, separate complete/claim paths, failed-write detection/cache reload, completed-unclaimed claim access and truthful completion feedback. Same-process concurrency/reload and scoped failed-write retries tested. Legacy completion hooks across separate stores are not a crash-atomic database transaction.
- **Q06/Q07 — repairs validated:** distinct-task thresholds, independent counters, actual completion-to-count wiring without extra XP stipend; multi-level XP consumption and stale-balance protection. Existing unlocked achievements/rewards are not retroactively revoked.
- **Q08/Q09 — scoped repairs:** preserve existing engagement/qualification thresholds; early completion no longer consumes later qualified chapter credit. Per-task chapter receipts prevent repeated credit; per-chapter reading stopwatch pauses on lifecycle backgrounding. Production provider early/qualified/repeat and target-matching tests pass. Modal-route timing and real-device lifecycle acceptance remain review items.
- **Q11 — repair validated:** malformed journal rows preserved, invalid top-level data blocks all writes, prior raw bytes backed up, failed save retains original entries, corrupt user identity not replaced. Save editor has error/double-tap safeguards; load failure is explicit.
- **NT90 schedule (Q12) — redesign only the faulty schedule:** new `plan_nt_90_v2` has 90 nonempty days covering the same 260 chapters in order. **Preserve** saved `plan_nt_90` enrollments as the exact original 87-step schedule, labeled Original Schedule. No step-index remapping or progress loss.
- **Defer existing broader issues:** duplicate progression/legacy in-memory board persistence, full-text certification, DST/timezone and cross-tab behavior, modal engagement, remaining content/accessibility/navigation checks retain their original roadmap scope. No new product expansion or architecture rewrite in this pass.

Validation: 28 tests passed (18 new integrity tests plus 10 existing tests). Static analysis: zero errors; the same 98 warnings and 26 informational diagnostics as the exact pre-pass baseline, with no new diagnostics. Content/import checks pass; source diff has no dependency, iOS project or Bible-text changes. Detailed root causes, safeguards, source checksum and limits are recorded in `docs/PASS1_INTEGRITY.md` in the development branch. Human Codespaces and iPhone validation remain required before release.

## Source index

All source findings refer to commit `6700909b56d837ca8b3f51ae113a13a2c3939622` in [the current repository](https://github.com/ScriptureQuest/scripturequest-app/tree/6700909b56d837ca8b3f51ae113a13a2c3939622).

- `lib/utils/bible_red_letter_helper.dart`, `lib/services/bible_rendering_service.dart`, `lib/screens/verses_screen.dart`: red letters, timers, completion controls, verse tools.
- `assets/bible/kjv.json`, `assets/verses/core_verses.json`, `assets/verses/scramble_verses.json`, `assets/games/emoji_parables.json`: audited content; game pools currently 8/6/8 entries respectively.
- `lib/providers/app_provider.dart`: `recordChapterRead`, `completeQuest`, `claimQuestRewards`, streak functions, daily/nightly helpers, persistence hooks.
- `lib/services/progress/progress_engine.dart`, `achievement_service.dart`, `user_service.dart`, `journal_service.dart`, `storage_service.dart`: reward/count/level/save findings.
- `lib/services/questline_service.dart`, `reading_plan_service.dart`, `chapter_quiz_service.dart`: nine guided definitions, seven plans, five quizzes, duration/reference checks.
- `lib/main.dart`, `lib/screens/quest_hub_screen.dart`, `profile_screen.dart`, `lib/config/build_flags.dart`, `test/bible_reader_test.dart`: routing, V2 states, placeholders, beta flag and test coverage limits.
- Prior Project Recovery Record and V2 assessment; retrieved November 29–30 planning; `architecture.md`, `replit.md` and Git history: history and intent, not proof that old claims are correct today.


## Latest approved execution — Pass 2 (2026-09-13)

**Implementation complete; awaiting Zeb’s Codespaces product review. Pass 3 has not begun.** See `PASS2_CONNECTED_EXPERIENCE.md` for behavior, safeguards, limitations, and the acceptance walkthrough.

VERIFIED: Today exposes XP/level and Daily/Weekly summaries/cards; five navigation destinations connect existing features. Three original guided Journeys retain identifiers/history with authored context and optional, explicitly skipped reflection steps. Reading advances matching persistent quests and active Journey steps through existing claim machinery. One completion result reports actual persisted deltas. Journey Board preserves completed history; the first Codex discovery follows qualified Psalm 23 reading and survives reload. Plans, saved verses and journal remain separate existing systems with clearer access.

VERIFIED validation: 39 tests passed, including all original 28 Pass 1/reader tests. Static analysis: zero errors, 98 warnings and 26 informational diagnostics, identical diagnostic set to the Pass 1 baseline. Actual VersesScreen rendering tests confirm John 3:4 and 3:9 use ordinary text, with Jesus’ speech in 3:3, 3:5 and 3:10 red. No additional red-letter data change was necessary. Phone (320/390 pixels), desktop (1280 pixels), and large-text widget checks passed. Final Web release build result is recorded in the handoff.

LIMITS: Cloud browser access to the local preview was blocked; no claim of a browser end-to-end click-through or access to Zeb’s Codespace. Native iPhone/VoiceOver and hands-on UX remain for review. Existing targeted tasks keep their terms; flexible daily/weekly reading slots appear at normal generation, not by silently rewriting saved tasks. Broad historical quest-template semantics remain future work. The 19 unmatched red-letter verses still need trusted-content review and remain non-red.

Roadmap classification: KEEP visible gamification, Journey Board, Codex, existing plans/games/journal. UPGRADE the connected reading/result/navigation experience. ADD one persistent passage-linked discovery proof. DEFER final art/themes/full Codex and learning expansion to approved Pass 3. REDESIGN repeated Journey enrollment as history-preserving revisits with no repeat completion payout; a future separately versioned repeat-play model needs review. No older approved idea is silently retired.

CURRENT STATE (supersedes earlier historical state blocks)
WORKING: Pass 2 connected implementation and 39 automated tests; Pass 1 integrity baseline retained.
BROKEN: No known failing scoped regression test; wider legacy content/quest semantics are not certified by this pass.
IN PROGRESS: Final transfer/handoff and Zeb’s product validation.
BLOCKED: Cloud-browser connection to local preview; native validation unavailable here.
NEEDS FROM ME: Test the connected loop in the existing Codespace and review the direction.
NEXT ENGINEERING ACTION: Address Pass 2 review findings only; wait for approval before Pass 3.


## Latest approved execution — Pass 3 (2026-09-14)

Pass 2 baseline `f6c9a57561ba54ae6c7ae9d40ba5e23dbdab1fec` was approved by Zeb. Pass 3 implements the bounded discovery → learning → remembering → further Scripture loop; see `PASS3_EXPLORATION_AND_MEMORY.md` for the detailed behavior, reward policy, validation, and acceptance walkthrough.

**KEEP:** Scripture-first reading, visible Daily/Weekly quests and XP/levels, three existing Journeys and their history, reading plans, original games, achievements, journal, saved Scripture, all Pass 1/2 protections.

**UPGRADE:** one Codex proof becomes four permanent passage-linked discoveries; Learn connects authored passage evidence, chapter quizzes, chosen-verse practice, and further Scripture. Chapter-quiz replay rewards are protected. Journey Board carries discovered/found evidence beside existing history. You gains remembered Scripture.

**ADD:** three honest recall evidence states, four explicitly categorized Scripture Connections, three code-native landscape covers, one related accomplishment-mark family, reduced-motion-compatible entrance, and a persisted plain/illustrated preference. Findings earn one 10-base-XP reward using existing streak adjustment; independent recall retains the existing daily verse reward scale. Daily/Weekly learning slots reuse existing target/reward values and preserve already-generated quests.

**REDESIGN:** automatic mastery claims become evidence of practiced/helped/independent sessions in the new experience. Existing legacy memory labels/data remain available rather than being silently migrated or discarded. Quizzes explicitly separate factual answers from ungraded reflection.

**DEFER:** expanded/externally reviewed content, final art library, atmosphere/theme packs, scheduled memory review, new games, universal legacy-game reward audit, and complete personal-history migration. These are retained future ideas, not removed from the original vision. No new currencies, fantasy mechanics, competition, or spiritual ranking.

CURRENT STATE — this entry supersedes older execution summaries:
WORKING: Pass 3 connected implementation; 54 regression/widget tests; release Web build; earlier integrity and progression behavior.
BROKEN: No known failing Pass 3 acceptance case in automated validation. Broader legacy issues remain classified in earlier audit sections.
IN PROGRESS: Zeb’s Codespaces acceptance/product review.
BLOCKED: Real-iPhone/VoiceOver validation and independent trusted-content review remain unverified here.
NEEDS FROM ME: Test the Pass 3 handoff in the existing Codespace and give product feedback.
NEXT ENGINEERING ACTION: Respond to Pass 3 review findings only. Do not begin the next phase without approval.


## Latest approved execution — Pass 4 (2026-09-16)

**Implementation and automated validation complete; awaiting Zeb's review.** The approved Pass 4 theme/product-cohesion scope supersedes the older Pass 4 scheduling. Details: `PASS4_THEMES_AND_PRODUCT_COHESION.md`.

**KEEP:** Scripture Light; visible Daily/Weekly Quests, XP/levels, Journeys and their history; Journey Board, Codex, discoveries, Connections, remembered Scripture; existing games, achievements, reading plans, journal and saved passages; all Pass 1–3 protections.

**UPGRADE:** designed Scripture Dark; shared semantic themes/components; expressive Learn and Play & Learn; family-based accomplishment cards and filters; cohesive You/personal-library surfaces; responsive game results and deeper-screen labels. Theme selection persists separately from earned progress, with an independent reader override.

**REDESIGN / STAGE:** modern V2 appearance now uses the new built-in theme registry. Unmodernized legacy routes retain a compatibility theme boundary. Existing cosmetic/theme-pack data remains; adapting its global preview behavior to the new system is deferred. No new pack shop or currency was added.

**DEFER:** earlier ownership/backup/onboarding work, full personal history, additional theme packs/atmospheres, final graphics library, broad legacy migration, word searches/crosswords/new games. Preserve these ideas for explicit future approval. Record the reported Journey/45-second qualification concern for the later integration/bug pass; do not treat it as fixed. The 19 unmatched red-letter verses still require trusted-content review.

VERIFIED: 62 tests passed; static analysis 0 errors/92 warnings/26 infos, no new diagnostic identities; production Web build succeeded on Flutter 3.32.8. Both themes checked across 88 screen/size combinations, with additional large-text controls and connected discovery/learning/remembering navigation. Actual John 3 rendering checks pass in both themes. Diff contains no progression-service, Bible-data, dependency or iOS changes. Browser/native acceptance is not claimed.

CURRENT STATE — supersedes earlier execution summaries:
WORKING: Pass 4 Light/Dark theme system and scoped deeper-screen modernization; full automated regression suite and Web build.
BROKEN: No failing scoped regression test; unrelated legacy diagnostics/issues are not certified by this pass.
IN PROGRESS: Transfer and Zeb's hands-on product review.
BLOCKED: Native-device/VoiceOver validation and trusted review of the 19 unmatched verses remain outstanding.
NEEDS FROM ME: Test both themes and the connected product in the existing Codespace.
NEXT ENGINEERING ACTION: Respond to Pass 4 review only. Do not start Pass 5, the comprehensive bug pass, or game expansion without approval.


## Pass 5 completed — Continuity & Content Foundations (2026-09-23)

Approved separately after the Post-Pass-4 assessment. The existing five tabs, visible Daily/Weekly quests, XP/levels, Journey Board, Codex and optional/private reflection remain authoritative.

**IMPLEMENTED:** shared typed connected-content boundary; existing Journey definitions extracted without changes to identifiers/templates/rewards; canonical passage relationships including many-to-many Journey discoveries; namespaced editorial orientations; read-only continuation resolver and state adapter; Today/onboarding handoff/result/Learn/discovery/finished-Journey integration; explicit destination ownership with Remembered Scripture history under You and practice under Learn. AppProvider remains the existing progression authority and grows only from 6,050 to 6,051 lines.

**VERIFIED:** 73 tests pass (all prior 62 plus 11 new), analyzer 0 errors/no new diagnostics (92 preexisting warnings, 26 infos), production Flutter Web build succeeds. Saved-state reads/restart, duplicate/reward protections, existing red-letter rendering, both themes, phone/large layouts and push/back navigation pass. Existing Journey definition values match the Pass 4 source. No persistence migration or content expansion. Implementation details, contracts and future registration instructions: `docs/PASS5_CONTINUITY_AND_CONTENT_FOUNDATIONS.md`.

**PRESERVE:** all Pass 1–4 behavior and previous deferred requirements. **DEFER:** comprehensive bug hunt, universal legacy-game receipt audit, full provider/storage/router decomposition, backup/restore and fuller onboarding, new content/game libraries, third theme, native/VoiceOver/release qualification and the 19 unmatched red-letter verses requiring trusted review. The earlier roadmap’s release-qualification Pass 5 is moved to a later approved milestone; it has not been silently retired or completed.

**Next gate:** Zeb tests this Pass 5 bundle in Codespaces and reviews continuity. No Pass 6 or broad bug/content expansion is authorized by completion of this pass.
