# Pass 5 — Continuity & Content Foundations

Implementation on `v2/reading-design`, based on approved Pass 4 `e71db8bc3c7eb239ebb975702b228e1121378b05`. Authorized by the supplied Pass 5 instructions. This implements the Post-Pass-4 assessment; it does not replace the approved five-tab product or begin the comprehensive bug pass.

## Architecture and ownership

| Boundary | Owner and contract |
|---|---|
| Existing Journey definitions | `lib/data/connected/journey_definitions.dart`: existing definitions moved from QuestlineService with identical IDs, step templates, metadata and rewards. QuestlineService continues to own transitions and persistence. |
| Connected relationships | `ConnectedCatalog`: curated Journeys, art scenes, chapter-learning entry metadata, canonical chapter relationships, discovery/Journey links, and Scripture Connection links. It reads existing discovery and Connection content; it does not make copies of those catalogs. |
| Editorial context | `journey_editorial.dart`: existing purposes and orientations. Orientation keys now include Journey ID and step ID; these are editorial lookup keys, not persisted IDs. The old JourneyContent helper remains a compatibility facade. |
| Canonical reference | `PassageReference`: uses the existing Bible book registry/parser, normalizes chapter identity (including Psalm/Psalms), rejects malformed and out-of-range chapters, and produces the existing `/verses?ref=` destination. It does not supply Scripture text. Existing bundled-text tests remain the authority for verse content. |
| State adapter | `ContinuityReader`: copies current focus, completed Journey IDs, discoveries, evidence findings, chosen memory keys, plan reading and recent reading into a snapshot. Read failure is surfaced, never treated as a fresh install or overwritten. |
| Guidance | `NextActionGuidance`: deterministic read-only resolver with no provider, persistence, clock, callback or reward-service access. Context is explicit. |
| Presentation | `NextActionPanel`: one contextual continuation using the existing theme. Does not mark anything complete. |
| Navigation ownership | `ConnectedDestination`: shared tab ownership based on route path, independent of query strings. Existing URLs remain intact; connected actions push so the actual caller stack remains available. |

AppProvider: **6,050 → 6,051 lines**. One import was added and its public curated-ID accessor now delegates to the catalog. No progression writer was moved, reimplemented or wrapped with another reward path. The 329-line definition block was extracted from QuestlineService because catalog relationships need access to the same definitions without depending on a state-writing service. A token comparison against the Pass 4 source confirms all definition values were preserved.

## Guidance priorities and context

1. Continue the focused active Journey. Today, reading results and Learn share this priority. A reflection step explicitly says it is optional and allows continuing without writing through the existing Journey controls.
2. With no active Journey, continue an unfinished active reading plan. The plan destination retains its existing step/schedule controls and saved legacy enrollments.
3. For the supplied passage, or recent reading when no passage is supplied, offer unfinished evidence learning only for a discovery already earned through reading.
4. In a learning context, offer another earned unfinished passage challenge, then chosen Remembered Scripture. This is an intentional contextual alternative when no Journey/plan has priority.
5. In a finished-Journey context, offer the next curated Journey not completed. When the curated set is finished, point to Journey Board for honest revisiting; do not label previously earned content as new.
6. Free reading remains a first-class continuation: return to the chosen passage and use the existing reader to continue. Guidance does not enroll the reader in a Journey.
7. With history but no active reading, revisit discoveries or the Journey record. A fresh user gets Getting Started.

No date-based punishment, overdue-task recommendation, expiring unlock, opaque personalization or inferred spiritual score is introduced. Recommendations do not allocate or award XP. Daily/Weekly quest cards, visible rewards and XP/levels remain unchanged. The resolver deliberately does not add a competing quest chooser: existing quest surfaces remain the authority for available tasks, while reading advances eligible goals through existing writers.

## User-visible changes

- Today’s main continuation recognizes an active Journey, reading plan or free reading rather than always falling back to choosing a Journey.
- The onboarding closing button says “See my first Scripture step”; setup still preserves its original enrollment/preferences and lands on Today, which resolves that step.
- Reading results keep actual XP, level, quest, achievement and discovery results. Only their next-action selection is replaced. “Keep reading” and optional reflection remain available.
- Learn’s featured continuation uses the same active-path priority. It no longer repeatedly presents the first discovery as a fresh featured challenge after everything is learned. All existing activities remain accessible below it.
- Journey Board, guided Journeys and Codex share passage relationships. A Conversation at Night now correctly links with both Getting Started and Knowing Jesus, through John 3, without changing its permanent discovery ID or earning record.
- Finished Journeys retain their accomplishment and offer a specific next Journey or a revisit destination.
- Correct finding results offer continuation alongside the existing discovery and remembering links.
- Remembered Scripture history belongs to **You**; practice belongs to **Learn**. Bible reading belongs to **Bible** regardless of where it was opened. Push/back retains origin context. No router replacement, path renaming or stateful-tab migration was attempted.

## Compatibility and modern/legacy activity contracts

| Activity | Existing write authority retained | Pass 5 obligation |
|---|---|---|
| Reader completion | AppProvider.completeReaderChapter; existing serial queue, qualified reading/event handlers and reward receipts | Read state after the writer returns; show the writer’s actual result. Never complete a chapter or task while resolving/rendering guidance. |
| Daily/Weekly tasks | Existing task credit, completeQuest/claim guards and reward receipts | Guidance does not assign, replace, claim or reward tasks. Cross-progression remains a consequence of legitimate existing activity. |
| Journey steps / optional reflection | QuestlineService transitions and AppProvider guarded public methods | Navigate to the existing step controls. Never infer completion from opening a recommendation or enrollment from opening Scripture. |
| Passage evidence | recordPassageFinding | Existing first-success and retry guards remain authoritative; next action reads the resulting state. |
| Chapter learning | completeConnectedQuiz | Existing completion receipts, legacy-result compatibility and actual XP results remain unchanged. Chapter metadata points to these existing routes. |
| Honest recall | recordRecallEvidence | Existing session outcome and per-verse/day reward protections remain unchanged. Guidance to practice is not practice evidence. |
| Legacy mini-games and memory | Existing game handlers / awardMiniGameXp / legacy memory entry points | No new reward adapter or parallel activity emitter added. Do not invoke both a legacy award and a connected award for the same future activity. A universal legacy-game receipt audit remains deferred. |
| Achievements | Existing achievement evaluation and guarded unlock/reward writers | Guidance reads accomplishments indirectly via existing history surfaces; it neither evaluates nor unlocks achievements. |
| Saved libraries/themes | Existing storage keys and providers | No migration, deletion, clearing, settings write or ownership change. |

Persisted user, plan, quest, Journey, Codex, recall, journal, bookmark, highlight and theme structures are unchanged. Unknown legacy history is not reclassified or migrated. No historical metadata is invented. The existing limitation that retired/missing Journey definitions cannot be displayed by the current history join remains deferred: retain definitions/IDs when adding content.

## Adding future content safely

1. Add a Journey definition in `data/connected/journey_definitions.dart` using a new stable Journey ID and step IDs. Never rename or reuse existing saved IDs; keep retired definitions available for history.
2. Register a curated Journey/art relationship in `ConnectedCatalog.presentations`; add its purpose and namespaced step orientations in `journey_editorial.dart`. Screens must not add `if (id == ...)` branches.
3. Add reviewed discovery/Connection content in the existing `data/exploration/catalog.dart`. Keep its stable discovery/Connection IDs, canonical references and current reward semantics. Shared-chapter relationships are derived automatically; the legacy primary `Discovery.journey` value remains compatible.
4. Add chapter activity content in its existing owning service, then register surfaced entry metadata in `ConnectedCatalog.chapterLearning`. Do not duplicate quiz answers in the relationship layer.
5. Run catalog validation, bundled-KJV evidence/endpoint checks, saved-ID tests and the connected-flow regressions. The test-only additional Journey proves relationships and onward guidance extend without screen changes. No production content was added for this proof.
6. New activity types must name one completion/reward authority and a replay identity before joining quest progression. A navigation target or guidance calculation must never become that authority.

This is deliberately not a remote CMS, a universal content schema, a new progression engine, or a generic game framework.

## Validation

Final validation (2026-09-23): **73 tests passed**, including all 62 prior tests and 11 new tests; analyzer **0 errors, 92 preexisting warnings, 26 preexisting infos**, no new diagnostic identities; production Flutter Web build succeeded on Flutter 3.32.8 with `--no-pub --no-tree-shake-icons` (existing cache accommodation, no dependency or SDK changes). New UI checks cover 20 screen/theme/size combinations plus actual push/back navigation; the existing 88-combination Pass 4 matrix also passes. Rendered light/dark phone and desktop output was inspected. `git diff --check` passes. New focused tests cover catalog compatibility and extension, invalid registration, canonical references, deterministic fresh/free/long-term guidance, routing ownership, actual qualified-reading transitions, optional responses, plan priority, finished-Journey history, corrupt exploration handling, and unchanged persisted key/value snapshots across ten repeated guidance reads. Restart tests verify actual saved next-step continuation.

UI tests exercise Today → Journey enrollment → Bible → back to Journey → back to Today at 320 and 1280 widths in both themes. Additional render checks cover result sheets, Learn, Codex and Journey Board in both sizes/themes. Existing Pass 1–4 suites continue to exercise XP replay, multi-level grants, journal protection, quest counts, saved plans, connected rewards, learning/recall and actual red-letter reader rendering.

Limits: widget navigation and rendering plus a Web build are not a live Codespaces browser or native-iPhone acceptance run. Test reading completion uses the protected qualified-completion entry point; this is not a new real-time 45-second timer qualification test. No claim is made about VoiceOver or native notification delivery; existing headless notification-plugin log messages remain outside this pass.

## Deferred work preserved

Comprehensive bug/polish audit; universal legacy-game reward/receipt audit; full AppProvider decomposition; broader storage transactions and backup/restore; full router/tab-stack migration; missing/retired-content presentation; deeper onboarding; third theme; new Journey/discovery/achievement/mini-game libraries; word searches/crosswords; native release qualification, iPhone/VoiceOver acceptance; and the **19 unmatched red-letter verses requiring trusted-content review**. The reported real-time reading qualification concern remains for targeted acceptance. No guesses or Scripture-data edits were made.

The original roadmap’s release-qualification milestone is deferred to a later approved pass, not cancelled or considered complete. Pass 6 and comprehensive bug work require separate user approval.
