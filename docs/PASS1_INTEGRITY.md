# V2 Pass 1 — Scripture and progress integrity

Scope: approved trust repairs on `v2/reading-design`, based on `6700909`. No Pass 2 work, redesign, XP-value change, dependency upgrade or native project change.

## Repair and verification matrix

| Issue / root cause | Repair | Regression evidence |
|---|---|---|
| Broad red-letter ranges colored narration and other speakers, and missed speech. | Replace ranges with exact speech spans from eBible's KJV HTML. Full-verse fingerprint guards offsets. Both reader and shared renderer preserve the verse's text and style only matched speech. | Import reproduces 2,009 mapped verses; exact-byte reproduction of map/report. Production helper tests every span and rendered verse, mixed narration, known false positives, omitted speech and mismatched text. |
| Repeated chapter button calls paid 10 XP independently of chapter history. | Serialize reader completions; persist balance and chapter receipt together. Deduplicate engine stats separately so retry after a partial write heals the counter. Previously saved chapter history is respected without retroactive awards. Qualified rereading can still progress tasks/streaks. Completion banner only advertises +10 when newly granted. | Concurrent/repeated event tests, provider early-then-qualified reread, storage failure between XP and stats, and retry tests. |
| Claiming called completion again, replaying mastery/loot/journey hooks. | Separate claiming from completion. Serialize claims, reload persisted task status, apply indexed reward receipts, mark claimed after rewards. Repeated completion checks the saved completed-task identity; simultaneous same-task calls share one future. Completed unclaimed cards expose Claim reward. | Production provider completion then concurrent claims and replay; no additional balance change after claim. Failed balance write/retry test. |
| Five-task achievements were unlocked after one event. | Count distinct task identities before testing the threshold. Counter receipts include counter name. Real task completion feeds counts without adding the event API's separate XP stipend. Journal creation uses its saved entry ID instead of a generic/empty event ID. | Four nightly actions remain locked; fifth unlocks. Repeat IDs do not advance counts; reflection count reaches five. |
| Large XP grants advanced only one level. | Consume every crossed `level * 100` threshold; preserve lifetime XP and existing amounts. Serialize profile mutations and prevent stale reward-summary updates from overwriting fresh balances. | 1,000 XP reaches level 5 with zero remainder; concurrent receipts, reload and stale profile save. |
| Journal decode failure became an empty mutation list, allowing overwrite. | Parse raw rows, retain malformed rows and unknown fields, refuse mutations on invalid top-level data, save prior bytes before mutation. Corrupt profiles fail closed rather than replacing identity. Editor retains text on save failure and guards duplicate taps; journal reports loading failure. | Mixed valid/malformed rows through add/edit/delete, concurrent inserts, exact original bytes after invalid JSON/top-level values, simulated failed write and successful retry. |
| Early chapter completion consumed later qualified weekly credit; reading threshold callback was stale. | Keep the existing 12-second engagement/45-second qualification distinction. Evaluate current threshold at completion, reset the qualified timer per chapter and pause on app lifecycle backgrounding. Tasks require qualification and store per-task chapter credits; qualified rereads remain eligible independently of lifetime chapter history. | Production provider early/qualified/repeated reading and service wrong-book, early, duplicate and multi-chapter tests. |
| Memorization/matching snippets mixed translations. | Correct the identified eight core and six scramble records to the exact bundled KJV, updating missing-word answers where needed. | `python tools/integrity/check_content.py`: 14 exact matches, answer-token checks, 66 books / 1,189 chapters / 31,102 nonempty sequential verses. |
| Fixed-size grouping produced 87 days under a 90-day title. | New enrollments use `plan_nt_90_v2`, exactly 90 nonempty days. Original `plan_nt_90` remains resolvable with its exact 87-step chapter grouping and an honest Original Schedule title. No saved progress indices are remapped. | New/old plan comparison: 260 unique ordered chapters, 90 vs 87 steps and unchanged original final step. |

## Scripture provenance and review boundary

Source: https://ebible.org/Scriptures/eng-kjv_html.zip (eBible KJV edition, public-domain text; source archive retained in recovery workspace).

SHA-256: `d08ea6360cb359b20fd13b0f17f71300c969c4e74a413836abbd189e005a88b7`.

The importer normalizes source whitespace and paragraph markers only, then requires an exact ordered phrase match in the existing verse. It does not replace the Bible or guess unmatched speech boundaries. See `tools/integrity/red_letter_import_report.json` for **19 unmatched verses**, which remain ordinary text pending trusted-content review. Red-letter boundaries are editorial annotation, not part of the inspired text itself. This is a sourced correction, not a claim that every Bible verse or every editorial boundary has been independently certified.

## Preserved behavior and limits

- Existing XP amounts, level thresholds, quest generation, reading thresholds and content identity remain. No retrospective deduction of rewards or achievements already earned.
- Native iOS project, bookmarks/highlights, reading-plan saves and Bible asset bytes are unchanged. Journal changes retain recoverable rows and previous raw data.
- Once-per-chapter reward uses the existing lifetime unique-chapter record; it does not prevent legitimate rereading or award a new chapter bonus merely for reopening a chapter.
- Receipts protect scoped rewards in a single app process and across normal reloads. This local SharedPreferences design is **not** a database transaction spanning every legacy mastery, random-loot and questline side effect, nor a cross-tab lock. Abrupt termination during those separate completion hooks remains a documented risk; do not claim crash-atomic completion of every subsystem.
- Legacy in-memory Journey/Quest Board persistence, duplicate streak systems, DST/timezone behavior, background timing while modal routes obscure the reader, broader mixed-text fixtures and remaining navigation/accessibility audits retain their existing roadmap entries. They were not expanded into a rewrite here.
- Native iPhone/VoiceOver and human Codespaces interaction remain separate review gates. Automated tests do not certify those experiences.

## Validation result

- `flutter test --no-pub`: **28 passed**, including **18 new integrity tests** against production code and 10 existing tests. Existing stand-in reader tests are not presented as production-screen interaction coverage.
- `dart analyze --format machine`: **0 errors**, 98 warnings, 26 infos. Compared against an isolated checkout of exact baseline `6700909`: **no new diagnostics**. Unrelated warnings intentionally retained.
- Content checker and reproducible importer: **passed**.
- `git diff --check`: **passed**. No changes to `pubspec.yaml`, lockfile, iOS project or `assets/bible/kjv.json`.
- Human Web preview, full Web release build and native iPhone/VoiceOver acceptance were not rerun in this pass. Production provider/services compile and execute in Flutter tests; this is not an App Store release certification.

The restored test runner uses Flutter 3.32.8 / Dart 3.8.1 and its pinned engine artifacts. The resumed environment had mixed-version generated cache files; only those required test components and missing locked packages were restored.
