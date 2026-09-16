# Scripture Quest V2 Pass 4 — Themes and product cohesion

Completed 2026-09-16 on `v2/reading-design`, from approved Pass 3 commit `378926bdedf82453ca63fe70d030a6206813ab74`.

## What changed

- **Scripture Light** remains warm paper and forest green. **Scripture Dark** adds midnight-blue surfaces, soft teal, readable pale text, and warm gold for accomplishments. Both share Lora headings, Inter interface text, responsive spacing, and accessible semantic colors.
- A theme registry (`ScriptureThemes`) and `QuestPalette` theme extension centralize visual decisions. Shared activity cards, responsive shelves, width constraints, and a compact level/XP panel support richer future themes without changing progression services.
- **Settings → Appearance** offers both themes and an independent reader-follow switch. The first explicit app-theme selection follows into the reader; subsequent theme changes respect a deliberately independent reader preference. Paper, sepia, and night reader choices remain available. Scripture has no decorative imagery behind its text.
- **Learn** presents a passage challenge from earned discoveries where available, then Play & Learn, Remembered Scripture, Codex, passage challenges, existing Chapter Learning, and reviewed Scripture Connections.
- **Play & Learn** presents the original matching, scramble, book-order, parable, and memorization activities as a cohesive library. Their content, scoring and reward logic are unchanged. Game completion actions return to Play & Learn instead of Community; the common completion panel now fits narrow layouts.
- **Achievements/Accomplishments** uses recognizable family symbols, earned gold borders, actual reward labels, recorded progress, earned dates, secret-item protection, and earned/unearned/family filters. Merely viewing or filtering does not grant rewards. Existing achievement identifiers, requirements and earnings remain unchanged.
- **You** gives Journey Board, Codex and Remembered Scripture prominent destinations above the personal library. Journal inherits the shared theme; Bookmarks, Highlights, Reading History, Settings and Profile receive compatible colors and mobile layout accommodations. Reading History returns to its caller, or You when opened directly.
- Smaller repairs within these surfaces include wrapping practice-status labels, readable chapter-difficulty text, compact XP presentation, readable feedback colors, and respecting reduced-motion settings in the shared entrance animation.

## Data and compatibility

Appearance is additive in `scripture_appearance_v1` and is separate from `app_settings_v1` and earned-progress records. Existing reader settings are retained on first load. Unreadable appearance bytes are not overwritten by loading. No user-data migration, XP/reward-value change, new quest formula, Bible-text edit, dependency update, SDK update, native-project edit, or backend change is included.

All Pass 1 integrity protections and Pass 2/3 progression, discoveries, remembering, optional reflection, Journey history and cross-progression remain in place. Daily and Weekly systems remain visible on Today. Existing passage-linked covers and discovery graphics are preserved; Pass 4 adds reusable themed components and accomplishment symbols, not a new raster-asset library.

Migration is deliberately staged. Unmodernized legacy routes retain their legacy theme boundary. Onboarding, older quest/detail/public-player surfaces and older cosmetic/theme-pack infrastructure are retained. The new built-in appearance setting is authoritative for modern V2 pages; the old cosmetic preview no longer controls the whole app. Adapting those older packs is deferred, not removal of their saved records.

## Verified validation

- **62 tests passed** in the full suite, including all earlier integrity/progression/content tests.
- **Static analysis: 0 errors, 92 warnings, 26 informational diagnostics; no new diagnostic identities** compared with Pass 3's 98 warnings/26 infos.
- **Production Flutter Web build succeeded**, using existing Flutter 3.32.8 and `build web --no-pub --no-tree-shake-icons`. The icon option is the existing preview accommodation, not a dependency upgrade.
- Real Flutter widget checks exercise 22 screens/result surfaces at 320px and 1280px in both themes (88 combinations), including seeded bookmarks, highlights, journal and reading history. Large-text (1.8×) appearance selection and achievement filters are exercised at phone width.
- Both themes exercise the existing discovery → passage evidence → remembering → further Scripture routes. Rendering assertions verify John 3:4 and 3:9 remain ordinary text and Jesus' speech in 3:3, 3:5 and 3:10 remains red.
- Theme persistence/reload, legacy reader preferences, independent reader overrides, invalid selections, preservation of unrelated saved records, and contrast checks pass. Reading-result surfaces use actual saved completion results. Browsing the expanded screen matrix does not change XP.
- Rendered light/dark screens were visually inspected and narrow-layout defects repaired. Final diff excludes unrelated preview/configuration changes; progression services, models, Bible data and native iOS files are unchanged.

These are automated Flutter render/interaction checks and a production compilation, **not** a claim of browser or native-device end-to-end acceptance. The previously established workspace browser-access limitation was not reinvestigated. The live reader's wall-clock qualification/return-after-absence behavior still needs Zeb's hands-on review; it was not bypassed or redesigned to pass these tests.

## Intentionally deferred

- Reported Journey/45-second qualification concern: retain for the separately approved integration/bug pass; not certified resolved here.
- The 19 unmatched red-letter verses: await trusted-content review; no guesses or additional attribution edits.
- Broad legacy game/content/reward audit, all unrelated analyzer diagnostics and runtime diagnostics outside scoped acceptance, native iPhone/VoiceOver, and comprehensive accessibility/keyboard checks.
- Additional games, word searches, crosswords, deeper memory challenges, final asset library, purchasable/custom theme packs, atmospheric expansion, and full legacy-screen migration.
- Previously planned backup/export, ownership/onboarding and personal-history expansion remain approved future concepts. The user's explicit Pass 4 theme/cohesion scope supersedes their earlier scheduling; those ideas are not silently retired.

## Codespaces acceptance walkthrough

1. Import the Pass 4 bundle using the accompanying transfer instructions; launch the existing preview on port 8080.
2. Open **You → Settings → Appearance**. Select Scripture Light, then Scripture Dark. Reload to check the saved preference. Turn reader-follow off and choose a reader preference independently.
3. On Today, confirm XP/level, Daily/Weekly progress and the current Journey. Continue into actual Scripture, read normally, and complete. Review the single completion result and its next action.
4. Open the earned discovery, Find it in the Passage, Remembered Scripture, and a further Scripture link. Check Journey Board retains history.
5. Open Learn → Play & Learn and Chapter Learning. Finish an existing activity and use its return action. Verify accomplishments show the existing earned items and rewards without paying them again.
6. Check journal, bookmarks, highlights and reading history with your existing data. Try phone-width and a wider browser in both themes. Check John 3:4 and 3:9 against Jesus' surrounding red-letter speech.

Stop after this review. Pass 5, a comprehensive bug hunt, and new-game expansion have not begun.
