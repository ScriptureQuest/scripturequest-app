# Scripture Quest V2 — Post-Pass-4 Product & Architecture Review

**Date:** 2026-09-22
**Reviewed baseline:** `e71db8bc3c7eb239ebb975702b228e1121378b05`, `v2/reading-design`
**Status:** Planning proposal for Zeb's review. Pass 5 is NOT approved or implemented by this document. Existing roadmap remains authoritative until approval.

## Executive judgment

**Keep the five-tab product and the existing Flutter application. Strengthen continuity and content boundaries before substantially expanding it.** The V2 is more than a Bible app with XP: qualified reading can advance a Journey and matching Daily/Weekly goals, leave a permanent discovery, open evidence-based learning, and lead to chosen-Scripture remembering. That is a credible Scripture Quest identity worth protecting.

The strongest path is connected. The entire application is not yet governed by one consistent set of product relationships. Older quests, memory records, game rewards, inventories and profile concepts remain alongside that path. More content added indiscriminately would multiply those differences.

I recommend **Pass 5: Continuity & Content Foundations**. Its visible result should be that a first-time, returning or finished-Journey user receives a sensible next action with an understandable reason. Its engineering result should be that existing content relationships and this guidance have clear owners outside the giant provider and individual screens. This is not a replacement progression engine, a new content campaign, or a general cleanup pass.

## Evidence and review limits

This assessment inspected the current working repository, routing, screen logic, onboarding, completion/learning orchestration, persistence, definitions and theme architecture. It also reviewed the Master Roadmap, Recovery Record and Pass 1–4 handoffs. The working tree started with only the known preexisting preview/configuration changes; production files were unchanged from the completed Pass 4 commit.

Pass 4's **62 passing tests, zero analyzer errors/no new diagnostics, successful production Web build and 88 screen/size checks** are prior validated baseline evidence, not tests rerun for this review. No new runtime bug hunt, browser session, native-device acceptance or production-code modification was performed. New-user and long-term assessments below are source-traced product judgments, not longitudinal user-study results.

**VERIFIED** identifies implementation facts. **ASSESSMENT** identifies my interpretation. **PROPOSED** identifies changes requiring review. Source paths are repository-relative; function/class names identify the relevant implementation.

## 1. Product structure: keep these five destinations

| Destination | Clear ownership | Verified current structure | Assessment / needed refinement |
| --- | --- | --- | --- |
| Today | What can I meaningfully do now? | XP, Daily/Weekly goals, focused Journey, reading continuation and optional activities | Correct command center. Journey continuation, featured daily reading and last reading are selected separately; they can offer different directions. Resolve their relationship explicitly without hiding quests. |
| Journeys | What would I like to explore? | Three curated Journeys, Reading Plans, older guided quests, Journey Board and Codex links | Keep guided Journeys and schedule-based Plans distinct. The curated/legacy split should become a clear catalog boundary instead of requiring users to understand two generations of the app. |
| Bible | Read Scripture freely and in context | Full reader, completion and verse tools; chapter activity feeds the connected loop | The center is strong. Preserve calm reading and free-reading credit. Entry/return context should be explicit rather than inferred entirely from route strings and current focus. |
| Learn | Explore, practice and remember what I encounter | Discovery challenges, games, remembered verses, quizzes and Connections | Good ingredients. Selection is still shallow: the featured challenge falls back to the first discovery when no unread evidence candidate exists. This is not an intentional all-complete or returning-reader recommendation. |
| You | What have I explored, earned and chosen to keep? | Journey Board, Codex, Remembered Scripture, achievements, journal, bookmarks, highlights, history, profile and collections | Correct long-term home. It is currently a set of destinations, not yet a coherent personal history. Keep the distinct identities of Board and Codex rather than flattening them into stats. |

**Intentional cross-links are not duplication.** Codex can be reached through Learn because it teaches, and through You because discoveries are kept. Remembered Scripture similarly belongs in learning and personal history. The concern is conflicting destination ownership or divergent records, not the number of entry points.

Navigation uses one GoRouter ShellRoute and manual path matching in `main_navigation.dart`, rather than independent stateful navigation branches for each tab. For example, `/remembered` selects Learn even when opened from You; achievements are outside the shell. These are structural inconsistencies, not proof of broken navigation. Preserve existing deep links, but give destinations explicit owning-tab and return-context metadata before the route set grows much further. Do not migrate the entire router merely to adopt a different pattern.

## 2. Scripture and game balance

**Protect:** visible XP/levels; real Daily/Weekly goals; purposeful Journeys; passage-based discoveries; evidence finding; honest recall states; accomplishment history; optional ungraded reflection; Scripture that is available without earning access.

The architecture supports a good distinction: Scripture is the activity, exploration supplies curiosity, and accomplishment records engagement. The reader is visually restrained while Learn and achievements are more expressive. Do not make every destination look like the reader or reduce progression to a hidden settings page.

The weak point is meaning after the reward. A level bar, a discovery record and a Journey completion all exist, but the app does not consistently explain what those accomplishments suggest doing next. More badges or currencies would amplify this problem. Levels should remain a summary of engagement; meaningful discovery, learning and history should carry the long-term motivation.

Legacy spiritual-rank language and artifact/profile machinery still exist. Their presence should not become the conceptual foundation for expansion. Keep their data, classify their presentation for later review, and avoid equating a title or score with holiness. No new theological claims or content corrections are proposed here.

## 3. Progression: connected core, several historical paths

| System | Verified implementation / relationship | Structural consequence |
| --- | --- | --- |
| Reading completion | `AppProvider.completeReaderChapter` serializes work, snapshots before/after state, invokes protected handlers and assembles `ReadingCompletion` | A useful existing integration boundary. Preserve it and its receipts; do not replace it with a second event pipeline. |
| Daily/Weekly quests | `TaskService` manages persistent tasks; chapter and learning receipts allow legitimate cross-progress | Keep recognizable goal systems and current reward policy. Their terminology/eligibility should become an explicit contract, not repeated string interpretation in new screens. |
| Guided Journeys | `QuestlineService` creates tasks for steps; progress and pending transitions are stored separately | Reuse this engine. Journey definitions and presentation need better ownership, not a new quest system. |
| XP/levels | `UserService` serializes balance grants and stores reward receipts; callers include progress/reward services and provider methods | A shared balance exists, but there is more than one route to it. An activity's display should report actual committed deltas, never independently calculate a second payout. |
| Achievements | Base definitions, seed definitions and dynamic unlocks coexist; UI reads persisted achievement state | More achievements need an explicit definition/trigger owner and duplicate-ID validation. Existing overlapping concepts are not automatically safe to merge or retire. |
| Discoveries/Codex | Exploration records persist, with compatibility for the earlier Shepherd record | Strong permanent evidence. Currently a tiny authored collection, not a scalable discovery-management system. |
| Remembering | New practiced/helped/independent sessions coexist with legacy memorization state | Preserve both honestly. Do not relabel old records as independent recall. A future unified shelf needs a compatibility adapter, not destructive migration. |
| Learning/games | New evidence, recall and connected quizzes use protected integration paths; older games call `awardMiniGameXp` and maintain their own completion state | Do not assume identical replay or quest-credit semantics across the library. Define an activity integration contract before adding more game types; audit old games separately. |
| Completion feedback | Reading returns a model; exploration methods return records/string change lists; legacy overlays observe event counters | One understandable user experience currently requires several presentation mechanisms. Typed outcomes are a useful future boundary; a new global event bus is not needed. |

**Judgment:** several related accounting/history systems, with a deliberately connected core—not one universal progression engine. They need consistent meanings and integration points, not a single giant database object.

## 4. Content scalability

Hard-coded Dart content is not inherently wrong. Small compiled catalogs are offline, reviewable and easy to test. Moving everything to JSON, a CMS or a backend would not by itself solve the current structural problem.

The important problem is **scattered relationships**:

- Journey definitions live inside `QuestlineService`; the three curated IDs also live in `AppProvider.connectedJourneyIds`.
- `JourneyContent` separately maps purposes and orientations, with orientations keyed by step ID alone.
- Journey covers are chosen by ID conditionals in a screen.
- Four discoveries and four Connections live in an already separated, typed catalog, but each Discovery also bundles a single challenge, answer, memory verse, scene and one Journey link.
- Chapter Learning has five quiz definitions, while Learn manually lists three entry points.
- Discovery/Board relationships depend in places on comparisons of display-reference strings. A passage appearing in several Journeys needs explicit many-to-many relationships, not just a discovery's single Journey string.
- History is joined against current Journey definitions. Removing an old definition can hide the corresponding record from that joined view even if storage retains it. Current records do not establish a full snapshot of the content as it existed when earned.

Before large expansion, introduce one authoritative, typed view of the **existing** connected catalog: stable content IDs, canonical passage identity, namespaced Journey-step identity, publication/retirement status, presentation metadata and explicit relationship lookups. Keep legacy IDs and adapters. Validate duplicate IDs, missing endpoints, passage validity and unsupported activity types automatically.

Catalog revisions and user evidence must be distinct. Never reinterpret previously earned progress when a guide's wording changes. Keep retired definitions resolvable or show an honest archived record. Do not invent historical text/revisions that were never saved.

**Do not add a CMS yet.** First prove that adding a test-only catalog fixture requires no new conditionals in Today, Learn or Journey Board. That is a more useful scalability test than changing the file format.

## 5. New-user experience, source-traced

The default user is local. Quest Hub checks onboarding state. With the current beta flag enabled, onboarding is six pages: welcome, beta information, reading comfort, reading rhythm, identity and closing. Finalization marks setup, enrolls a starter Journey (prefers `foundations`, otherwise the first available definition; currently Getting Started), creates starter reading/reflection tasks, attempts starter artifact/title grants and returns to Today. Focus can fall back to an active curated Journey.

| User question | Current answer | Assessment |
| --- | --- | --- |
| What do I do first? | Onboarding, then Today and Continue Journey | Understandable, but configuration precedes meaningful Scripture and the reading handoff takes extra navigation. |
| Why should I do it? | Journey purpose and passage orientation | Stronger than generic task instructions; retain it. |
| What happens when I finish? | Explicit completion records reading; qualifying reading advances eligible goals | Good model, but the visible completion action and 45-second qualification distinction require hands-on review. Do not change the rule during architecture work. |
| What did I earn? | Actual XP and progression/discovery changes in a result | Strong. Keep one result rather than competing popups. |
| Where did it go? | Journey Board, Codex, achievements and personal library | Destinations exist; the first successful session should make that ownership more evident. |
| What next? | Next Journey destination or exploration link | Sometimes an appropriate continuation, sometimes a generic library. Selection is not centrally coordinated. |
| Why tomorrow? | Continuing Journey, refreshed goals and saved progress | Credible motivation, but not yet a clear personal return plan. Avoid promises of new content every day. |

Do not redo onboarding wholesale in Pass 5. Improve the existing finishing handoff into the starter activity. Preserve name/comfort preferences, optional reflection and all saved setup flags. The larger onboarding/ownership work remains deferred.

## 6. Long-term experience

**Day 1:** the connected reading, reward and first-discovery loop has substance. Excess navigation and parallel prompts can obscure the primary action.

**Week 1:** resumed Journeys, visible daily/weekly goals and kept discoveries give momentum. Practice and quiz replay remain useful, but recommendations do not yet adapt thoughtfully to what is already complete.

**Month 1:** the limitation becomes depth. Four discoveries and a small curated Journey/challenge set cannot promise endless novelty. History accumulates, but the app provides limited help deciding which completed passage to revisit or which unfinished path to continue.

**Several months:** Journey Board and Codex give earned activity a permanent home; remembered sessions and reading records provide valuable material. However, exploration sessions are stored within one JSON document per user and parsed/re-written for updates. There is no observed load benchmark supporting a performance threshold, no complete content-version history, and no complete unified personal timeline or backup/restore experience in the reviewed paths.

The answer is not a streak treadmill. Invest in ownership, revisit value and content relationships. Scheduled spaced repetition, expanded history and backup deserve later dedicated milestones; do not falsely present existing raw counts as those finished systems.

## 7. Design-system architecture

**Keep the current design.** `ScriptureThemes`, `QuestPalette`, shared activity/progress components and independent reader preferences establish a useful foundation. Modernized routes use it; deferred routes deliberately retain a legacy theme boundary.

This is extensible scaffolding, not a fully data-driven theme engine. `QuestPalette` branches on a `night` boolean; colors also remain in reader styles, the legacy theme system and individual widgets. Spacing, radii and some surface decisions remain local. Legacy aliases such as `neonCyan` now map to calmer semantic colors but still carry historical naming. `main.dart` separately maintains a modern-route allowlist.

Two themes are well served. A genuinely different third palette should first make semantic palette values constructor-driven, define reader/exploration/accomplishment surface roles, and test contrast across those roles. Do that when the next theme is approved, not as an excuse to retheme everything now. Preserve the option for expressive exploration and entirely plain reading. Old cosmetic preview integration remains explicitly deferred.

## 8. Engineering hotspots and sequencing

Fresh physical-line counts under `lib`, not complexity scores:

| File | Lines | What matters |
| --- | ---: | --- |
| `providers/app_provider.dart` | 6,050 | UI notifications, content selection, saves, progression orchestration, memory, plans, inventory and onboarding are coupled. |
| `screens/verses_screen.dart` | 3,386 | Reader rendering, navigation, timers, tools and completion UI coexist. Keep stable during the next structural slice. |
| `services/quest_service.dart` | 1,789 | Several task types, generation and compatibility responsibilities. |
| `widgets/task_card.dart` | 1,524 | Presentation and task interaction paths span legacy/V2 concepts. |
| `screens/main_navigation.dart` | 809 | Tab matching, onboarding tour and several reward presentation signals coexist. |

Total `lib/**/*.dart`: **46,481 lines**. Provider growth from the recorded September 11 count of 4,891 is **1,159 lines (about 24%)**. Counting conventions may differ from that historical audit. Large generated Scripture data is not itself architectural debt.

**Restructure selectively before major expansion.** Extract connected content lookup and next-action decisions into small testable services/read models; keep `AppProvider` as a compatibility facade. New widgets should consume explicit relevant state rather than receiving authority to orchestrate rewards. Then extract completion orchestration in a separately reviewed, characterized slice if needed. Do not simply split the provider into files or create a new coordinator that takes the entire provider as a dependency; that hides the coupling.

Existing serial queues, receipts, pending Journey/quiz transitions and failure behavior are valuable. Preserve their identifiers and call ordering. SharedPreferences is a local key/value store, not an all-or-nothing transaction across every subsystem. Process-local queues do not establish cross-tab/device synchronization. Add storage ownership/schema documentation and representative size/failure tests before a backend or database decision. No present benchmark justifies an immediate database migration.

## 9. Findings by required category

### A. STRUCTURAL — influence the next pass

1. Scattered connected catalog relationships and string-based passage/step matching.
2. Independent next-action selection in Today, Learn and completion.
3. Oversized provider needs read-side boundaries before more content-specific conditions accumulate.
4. Route ownership/return context are manually inferred, including cross-linked personal/learning destinations.
5. Content retirement/version policy is needed to keep historical records interpretable.
6. Later activity growth needs one documented integration contract: eligibility, reward owner, receipt identity, result and return destination. Preserve existing writers while defining this contract.

### B. PRODUCT — important experience work

1. Better first-reading handoff and first-accomplishment ownership cues.
2. Intentional no-active-Journey/all-curated-content-complete states.
3. Clear distinction between guided Journeys, reading schedules and Daily/Weekly goals.
4. Remembered Scripture as a personal practice record, with understandable access to legacy memory history.
5. Valuable free-reading history should remain discoverable even without Journey enrollment.
6. Journal/bookmarks/highlights/Profile remain useful but not yet a fully organized personal-history experience.

### C. CONTENT — later expansion

Additional reviewed Journeys, Codex entries, Connections, achievement families, quizzes and memory activities; later word searches, crosswords, verse puzzles and mini-games. Grow content only after a stable catalog/eligibility contract. Preserve authored commentary boundaries and distinguish explicit quotations from editorial thematic links.

### D. BUG / POLISH — separate later comprehensive pass

The reported Journey/45-second concern; wider legacy task semantics (including distinct-day/book goals), game reward/replay coverage, inconsistent historical labels, broader return/scroll behavior, and existing analyzer/runtime diagnostics. These are retained for focused reproduction, not newly declared fixed or universally broken. The 19 unmatched red-letter verses remain pending trusted-content review; their attribution must not be guessed.

### E. PLATFORM / RELEASE — appropriate later milestone

Backup/restore and data portability; cold-start/upgrade/offline/interruption testing; real iPhone/VoiceOver and keyboard/accessibility review; TestFlight signing/build/configuration; beta flags/support/reminders; Scripture provenance/editorial review; optional future cloud sync. Local persistence is not a backup. Codespaces success is not App Store readiness.

Earlier family-discussion, seasonal content, audio/TTS, additional sourced translations and optional accounts remain deferred. Avatar equipment, shops, currencies, global rankings, chat/guilds and AI spiritual-advice systems are not new release requirements. No older approved idea is silently retired by this proposal.

## 10. Proposed Pass 5 — Continuity & Content Foundations

### Core objective / why now

**Make the current content behave like one continuing Scripture Quest, and establish the content/read-state boundary required to grow it.** This addresses the product seam exposed by the first four passes while avoiding another makeover or dangerous reward rewrite.

### Exact bounded scope

1. **Connected catalog ownership.** Consolidate the existing three curated Journeys' presentation/relationship metadata and four discoveries/four Connections, plus the current Chapter Learning entry metadata, into one typed lookup boundary. Adapt existing definitions; do not clone competing sources of truth. Use stable/namespaced IDs and canonical passage references. Preserve old Journey definitions and content records through compatibility lookups. Add catalog relationship validation and a documented revision/retirement policy.
2. **Exploration overview and next-action resolver.** Build read-only typed state for active Journey/step, available reading, Daily/Weekly summaries, earned/not-yet-explored discoveries and chosen memory. Resolve one primary action and a small optional learning action, with an explicit reason. Priority: user's active Journey; active reading-plan continuation when no Journey is selected; existing free-reading continuation; starter exploration when empty. An optional reflection must offer a clear ungraded continuation. Completed users get an honest revisit/explore state, not a claim that the first discovery is new. All decisions consume existing progress and do not grant anything.
3. **Wire existing surfaces, without redesign.** Today/TodayJourney, Guided Journey continuation, the reading-result next-action area, Learn's featured challenge, and the onboarding closing handoff use this boundary. Journey Board and Codex consume the same relationships so their links agree. Keep visible Daily/Weekly cards, XP and direct Bible access.
4. **Explicit destination ownership.** Centralize only the connected route descriptors needed by those actions, including owning tab and return context. Preserve URLs/aliases. Treat remembered practice as Learn and its saved history as an explicitly linked personal destination; document the choice instead of inferring it from arbitrary path substrings. No full router replacement.
5. **Compatibility and architecture gate.** Keep existing reward, task, Journey, memory and storage writers unchanged wherever possible. Document their activity contracts for later game growth. Remove the connected read/selection logic from the provider/screens as it is replaced; do not pursue a target line count. No requirement to extract every completion writer in this pass.

### Dependencies and risks

Dependencies: approved Pass 4 baseline and this scope; existing catalog identities, legacy fixtures and baseline regression tests. No new service, credential, payment, SDK or database is required.

Main risks: changing content identity can orphan history; changing entry/return context can lose a reader's place; duplicate catalog sources can drift; read-only guidance can accidentally become a second progression authority. Controls: stable IDs, adapters, deterministic read models, existing write paths and before/after saved-data checks. Do not promise new historical metadata for past records that never stored it.

If the work requires reworking accounting or migrating stored progress to make the next-action layer function, stop and narrow the implementation rather than silently expanding this pass.

### Acceptance criteria

- Fresh setup lands on a clear existing starter reading/Journey action while preserving saved preferences; reflection remains optional.
- An existing Journey resumes the correct next step after reload; no enrollment or reward history is reset.
- A reader with a plan but no Journey receives a useful plan continuation; a free reader can continue without enrolling.
- After a completed reading, Today and completion agree on the next meaningful action; eligible Daily/Weekly results and actual XP remain visible.
- A user who has finished the curated set sees honest continuation/revisit choices. Previously found evidence is not presented as a new unlock.
- Codex and Journey Board resolve the same existing passage relationships, including shared passages and legacy identities.
- Adding a test-only catalog entry requires no new content-ID branches in the connected screens. Invalid references/duplicate IDs/missing endpoints are rejected by content tests. No new production content is needed for this proof.
- Merely computing guidance, navigating or viewing history never grants XP or alters progress. Existing duplicate/retry/corruption protections all pass.
- Relevant real routes work at phone/large widths in Scripture Light/Dark; reader return context is preserved. Full tests, analysis and Web build pass.
- Review the final diff and update roadmap/recovery only after the implementation is approved. Deliver a separate commit/bundle when that future work is complete.

### Explicit exclusions / what remains afterward

No theme redesign, new graphics library, new Journeys/discoveries/games, changed XP/streak/qualification rules, whole-provider split, storage migration, universal reward-engine rewrite, full onboarding replacement, full personal timeline, backup implementation, TestFlight release work, or comprehensive bug hunt.

Afterward: a focused ownership/backup and first-use milestone, the separately approved comprehensive integration/correctness pass, reviewed content expansion, and native/release qualification remain necessary. Their ordering should follow product review and release intent. This proposal moves the old roadmap's release-qualification Pass 5 later; it does not pretend those requirements are complete or cancel them.

## Source index

- `lib/main.dart`; `screens/main_navigation.dart`: shell, routes, compatibility theme boundaries and selected-tab logic.
- `screens/quest_hub_screen.dart`; `widgets/connected/progress_summary.dart`: task selection, continuation and focused Journey presentation.
- `screens/connected/journeys_screen.dart`; `widgets/connected/journey_content.dart`: curated catalog filtering, Board/history presentation, orientations and links.
- `providers/app_provider.dart`: `completeReaderChapter`, `_runExploration`, `_creditExplorationGoals`, `recordPassageFinding`, `recordRecallEvidence`, `focusedJourney`, `journeyHistory`, `completeOnboardingSetup`, `awardMiniGameXp` and the legacy progression paths.
- `services/questline_service.dart`; `models/questline.dart`: definitions, step templates, persistent history and serialized transitions.
- `services/quest_service.dart`; `services/progress/progress_engine.dart`; `services/user_service.dart`: tasks, event handling, XP ownership and receipts.
- `services/storage_service.dart`; `services/exploration/exploration_service.dart`: local persistence and exploration-record boundaries.
- `data/exploration/catalog.dart`; `screens/connected/exploration_screen.dart`; `services/chapter_quiz_service.dart`: authored content, featured selection, remembering and quiz coverage.
- `services/achievement_service.dart`; `data/achievement_seeds.dart`; `screens/achievements_screen.dart`: definitions and accomplishments.
- `screens/onboarding_screen.dart`; `config/build_flags.dart`: current first-use flow and beta mode.
- `theme/scripture_theme.dart`; `providers/settings_provider.dart`; `widgets/bible_reader_styles.dart`; `widgets/product/product_ui.dart`: themes and presentation boundaries.
- `docs/Scripture_Quest_V2_Master_Roadmap.md`, `docs/Scripture_Quest_Recovery_Record.md`, `docs/PASS1_INTEGRITY.md`, `docs/PASS2_CONNECTED_EXPERIENCE.md`, `docs/PASS3_EXPLORATION_AND_MEMORY.md`, `docs/PASS4_THEMES_AND_PRODUCT_COHESION.md`: approved history and deferred work.

**Decision requested:** approve or revise the proposed Pass 5 scope. No implementation has begun.
