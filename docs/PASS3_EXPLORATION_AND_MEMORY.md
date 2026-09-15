# Pass 3 — Discovery, learning, and remembered Scripture

Base: `f6c9a57561ba54ae6c7ae9d40ba5e23dbdab1fec`, branch `v2/reading-design`.
Pass 2 is approved. This is a separate, additive Pass 3 implementation. No later phase is authorized.

## What is implemented

- **Codex:** four authored passage-linked discoveries: The Shepherd’s Care (Psalms 23), The Word Among Us (John 1), A Conversation at Night (John 3), and Refuge Amid Upheaval (Psalms 46). Qualified chapter reading adds a permanent discovery, whether in a Journey or free reading. Guides are open before earning; Scripture is never locked. Earlier Shepherd records retain their original earning context and do not announce rediscovery. Guide text is explicitly commentary, not additional Scripture.
- **Find it in the Passage:** one authored observation per discovery, using the actual bundled KJV chapter. The reader finds the verse containing the evidence; an optional clue helps. Incorrect choices do not grant progress. Correct completion saves evidence permanently and grants 10 base XP once, using the existing streak adjustment and reward receipts. Revisits remain available. Successful selection scrolls to a single result with quest changes, XP, level/achievement changes, and links onward.
- **Learn:** passage challenges, remembered Scripture, four scoped Scripture Connections, existing chapter quizzes for John 3/Romans 8/Psalms 23, and the original games library. Existing games are preserved rather than recreated or represented as fully audited.
- **Remembering:** choose a verse in the Bible reader, from saved verses, or from a discovery. Study the complete canonical verse, hide it, optionally reveal it, then self-report **practiced**, **recalled with help**, or **recalled independently**. Revealing the passage removes the independent-recall option for that attempt. Each session is saved once; outcomes cannot be changed by a retry. The shelf shows distinct evidence counts, not holiness or inferred mastery. Previous memory records remain in the original library; new evidence does not overwrite them.
- **Memory rewards:** independent recall uses the existing 10-base-XP daily verse reward scale and streak adjustment. Canonical verse/day receipts prevent duplicate payment, including book aliases. Earlier legacy daily awards are respected. Practicing or recalling with help may complete a learning quest, but does not independently receive the recall stipend. The result reports the actual combined XP delta.
- **Chapter quizzes:** preserve existing questions, difficulty amounts (10/15/20), and ungraded reflections. Completion now uses a saved pending result plus receipts for XP/statistics, rather than paying on every replay. Previously completed chapters are grandfathered without a new quiz stipend. A failed marker write can be retried. The screen offers the actual passage before and after the quiz and no longer equates a quiz score with memorization.
- **Daily/Weekly quests:** newly generated sets reuse one existing non-primary slot as “Explore and remember,” preserving that slot’s target and rewards. The flexible chapter slot remains. Saved current quests are not migrated. Distinct findings, verse practices, and chapter quizzes can advance eligible learning goals once per activity per quest; matching targeted memory goals still require the matching passage. Early/expired/future tasks do not receive this credit. Generic quiz events cannot bypass the new learning receipt path. No learning activity pretends to complete a reading chapter or Journey step.
- **Journey Board and You:** existing Journey history gains illustrated covers and links to earned passage discoveries, including whether evidence has been found. You retains Journal, bookmarks, highlights, achievements, reading history, settings, and prior collections; remembered Scripture is added as a first-class personal destination. Journey detail links directly to its relevant discoveries.

## Scripture Connections proof

| Kind | Pairing | Claim boundary |
| --- | --- | --- |
| Explicit quotation | John 1:23 → Isaiah 40:3 | John names the prophet; both contexts remain accessible. |
| Parallel accounts | Mark 4:35–41 → Luke 8:22–25 | Compare accounts of the storm; no invented harmonization. |
| Recurring imagery | Psalms 23:1 → John 10:11 | Shared shepherd imagery; not labeled a quotation. |
| Editorial thematic connection | Psalms 46:1 → Philippians 4:6–7 | Suggested reading pairing; not a claim of direct interpretation. |

All endpoints and challenge evidence were checked against bundled KJV text. This is a bounded editorial prototype, not a claim of independent scholarly/theological approval. Verse-range links open the Bible in the relevant chapter so surrounding context remains available.

## Visual proof

Three original Flutter vector landscapes: morning light, sheltering hills, and night study. These form Journey/Codex covers, adapt to the existing reader night palette, and require no downloaded images or new packages. Three related accomplishment marks use existing Material icons for exploration, finding evidence, and remembering. A restrained 320 ms mark entrance respects disabled animations. The optional illustrated-exploration preference is additive and persisted. Images never appear behind Scripture. The existing plain Bible surface remains unchanged.

This establishes a small scene-key/presentation boundary for later book imagery and themes; it does not ship a theme store, full atmosphere library, or historical maps. Landscapes are symbolic, not depictions of verified biblical locations.

## Validation and boundaries

- Full suite: 54 tests, including all 39 Pass 1/2 baseline tests and 15 Pass 3 tests.
- Content evidence, verse validity, all Connection ranges, persistence/reload, qualification, legacy Shepherd retention, finding replay/concurrency, distinct recall outcomes, same-day/alias reward protection, corrupted-record preservation, quiz replays and interrupted-result recovery.
- Actual Flutter widget interactions: discovery → find evidence → practice → remembered shelf → Codex → actual Bible reader. Rendering at 320/390 and 1280 pixels; night-reader palette, 1.8 text scaling, optional artwork, and reduced-motion setting. Rendered screenshots inspected.
- Existing actual-reader John 3:4/3:9 attribution tests continue to verify ordinary text while Jesus’ tested speech remains red. No Bible source or red-letter data was changed in Pass 3.
- Static analysis: zero errors; baseline diagnostics retained, no new diagnostic identities.
- Flutter 3.32.8 release Web build: `build web --no-pub --no-tree-shake-icons`. The established icon-cache accommodation remains build-only; no SDK or dependency upgrades.
- This workspace’s browser cannot access its localhost server. Validation is actual Flutter widget execution/rendering plus a release Web build, not a claim of remote Codespaces browser testing or real-iPhone testing. Zeb’s existing Codespace remains the human acceptance surface.

## Acceptance walkthrough

1. Open Today: Daily/Weekly quests, XP, levels, and current Journey remain visible. Existing saved quests retain their current terms until ordinary regeneration.
2. Read John 1 or Psalms 46 in the Bible, spend the existing 45-second qualifying time, and complete the chapter. Open the newly earned Codex entry from the result.
3. Choose **Find it in the Passage**. Try a wrong verse, optionally reveal the clue, then find the correct evidence. Inspect the single result and eligible quest changes. Revisit: the challenge stipend does not repeat.
4. Follow **Remember a verse from this passage**. Study, hide, then reveal for help: only the helped outcome is offered. Save and open **My remembered Scripture**. Separately try independent recall without revealing; repeat that day and verify no second verse stipend.
5. Reload the preview. Discoveries, evidence, practice outcomes, Journey history, and earlier rewards remain. These local records persist in the same browser/profile/origin; a different preview hostname has separate browser storage.
6. Open the discovery’s Scripture Connections and follow both passage links. Return to its Journey/Board; see the kept discovery beside relevant Journey history.
7. Learn → an existing chapter quiz → complete → retry. The previous quiz stipend is retained, not paid again. Read the chapter from its explicit link.
8. You → turn **Illustrated exploration** off/on. Try the existing reader night setting and narrow/wide layouts. Scripture remains on a plain readable surface throughout.

## Intentionally deferred

Large Codex/Connections libraries, specialist content review beyond the bounded guides, scheduled spaced repetition, automatic speech/text grading, new achievements with additional XP, full personal-history timelines, final commissioned illustration packs, historical maps, atmospheric reader themes/backgrounds, and broader redesign/audit of legacy mini-games. Existing legacy mastery/achievement labels remain in their original surfaces; the new evidence system does not reinterpret those records. Remaining 19 unmatched red-letter verses still require trusted-content review and remain ordinary text. Native iPhone/TestFlight, VoiceOver, and Codespaces acceptance require device/user validation. No later implementation phase has begun.
