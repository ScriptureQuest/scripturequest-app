# Scripture Quest — Project Recovery Record

Updated: 2026-09-12 • Pass 1 integrity implementation; earlier recovery entries below are historical

## Scope and evidence

Recover the existing TestFlight-era application. Do not rewrite, redesign, migrate, upgrade dependencies, or substantially change source during recovery inspection.

VERIFIED means observed in the recovered repository, Git history, or a named read-only check. It does not mean the app was executed successfully. USER-REPORTED means stated by the owner. INFERENCE means an assessment supported by evidence. UNKNOWN means not established.

Inspected source: https://github.com/ScriptureQuest/scripturequest-app
Pinned revision: ddd3412778cf45206e6f9bddae9067c82866214b
Local checkout: /workspace/scratch/e33aa9ed0a1d/scripturequest-app

## 1. Source-code locations

VERIFIED: Public repository cloned successfully, including all advertised branch history. Contains 142 Dart files under lib/, Flutter assets, Android/iOS/web projects, tests, and documentation. Working tree remained clean throughout inspection.

UNKNOWN: Other repository contents, local-only work, unsynced Dreamflow/Replit changes, private branches or backups outside this repository.

## 2. Repository / branch / commit

VERIFIED:
- Default and only advertised branch: main. No tags and no merge commits in recovered history.
- 90 commits, beginning 2025-12-11 with 81ac6c79bdb40949bc02350f64900282c22dfa0a, “Initial Dreamflow sync.” This already contains a substantial application; earlier development is not represented as incremental history here.
- Latest commit: ddd3412778cf45206e6f9bddae9067c82866214b, 2026-01-03 23:31:14 UTC, “feat(tasks_screen): rename Task Board to Quest Hub and default Tasks”.
- Its parent: fdb0bf8f404e316570f98aca9ce2b71b91d0cc55, build-number update to 1.0.1+9 (2025-12-19 00:35:32 UTC / December 18 in the author's timezone).
- GitHub API returned no releases and zero Actions runs. Public account repository listing returned only scripturequest-app at inspection time; this does not rule out a second private repository or one under another owner.

## 3. Technology stack

VERIFIED: Flutter/Dart; internal package name level_up_your_faith; application version 1.0.1+9. pubspec.yaml declares Dart ^3.6.0. Committed lockfile declares Dart >=3.8.0 <4.0.0 and Flutter >=3.32.0. replit.md reports Flutter 3.32.0 / Dart 3.8.0; that is documentation, not a verified successful build environment. .metadata stores stable-channel revision 6fba2447e95c451518584c35e25f5433f14d888c, not an enforced SDK pin.

Selected locked dependencies:

| Package | Locked version | Role |
|---|---|---|
| provider | 6.1.5+1 | Application state |
| go_router | 16.3.0 | Navigation |
| shared_preferences | 2.5.3 | Local persistence |
| google_fonts | 6.2.1 | Typography |
| flutter_local_notifications | 19.5.0 | Device reminders |
| share_plus | 12.0.1 | System sharing |
| package_info_plus | 9.0.0 | Version/build metadata |
| device_info_plus | 12.3.0 | Device details for feedback |

Other direct dependencies: timezone 0.10.1, intl 0.20.2, uuid, url_launcher, cupertino_icons, Flutter. Development dependencies include flutter_test, flutter_lints, flutter_launcher_icons and flutter_native_splash.

UNKNOWN: Exact SDK/Xcode combination used for the last Apple upload and whether all locked packages resolve and compile together today. No dependency resolution or upgrade performed.

## 4. iOS build architecture

VERIFIED: Standard Flutter Runner Xcode project/workspace, Swift AppDelegate registering Flutter plugins, CocoaPods Podfile, Runner scheme, Info.plist, splash assets and app icons. Swift setting 5.0; project deployment target 12.0; Podfile global platform declaration is commented out. Flutter build variables supply application version/build.

VERIFIED concern: Podfile.lock contains only Flutter and path_provider_foundation, while Dart dependencies include additional native plugins. It dates to the initial sync and is not a complete lock of the current iOS plugin set. Records CocoaPods 1.15.2. Native dependency resolution will need inspection during baseline restoration; this alone is not evidence the historical upload failed.

UNKNOWN: Signing team, signing assets, export configuration, Xcode version, actual build-time overrides and upload system. No DEVELOPMENT_TEAM setting found in project.pbxproj. No Fastlane/Codemagic/GitHub Actions release pipeline found in the checked tree.

## 5. Frontend architecture

VERIFIED: lib/main.dart creates MultiProvider, AppProvider, SettingsProvider, equipment/inventory providers, BibleService and CosmeticService; MaterialApp.router uses go_router with a MainNavigation shell. Screens, widgets, models, services and themes are separate directories.

The root route / STILL opens QuestHubScreen. /tasks opens TasksScreen after the January 3 commit. The January commit title/comments imply a new default, but the actual root route was not changed. Both screens coexist, along with older home/quest-board screens. This is a verified inconsistency in naming/documentation, not permission to pick a different landing screen.

AppProvider is 5,578 lines and coordinates persistence, progression, reader state, quests, achievements and rewards. This concentration of behavior makes targeted verification important; no refactor recommended during recovery.

## 6. Backend architecture

VERIFIED within this repository: core business logic lives in Dart services on the client. No backend server, Firebase/Supabase integration, remote database client or app API endpoint was found in inspected source/configuration. Historical filename review also found no separate backend deployment structure.

INFERENCE: No separate backend appears necessary to restore this checkout's core reading/quest experience. Absence here does not establish what may exist in a second repository or external account.

## 7. Database / storage

VERIFIED: StorageService wraps shared_preferences; services persist JSON strings and primitive values for users, reading history, quests, journals, settings, friends, inventory and related state. Some board/inventory state is initialized in memory. There is no verified cloud synchronization or server-side backup workflow.

VERIFIED asset structure: assets/bible/kjv.json parses successfully and contains 66 books, 1,189 chapters and 31,102 verse entries. This is a structural count, not a verse-by-verse editorial validation. KJVBibleService loads it for the reader. tool/kjv_builder.dart documents a conversion workflow from aruljohn/Bible-kjv; original input files are not required to read the already bundled output.

## 8. Authentication

VERIFIED: UserService creates a device-local UUID user when no saved profile exists, with a default name/email placeholder. No remote login, password flow or account identity provider found. Profile/public-visibility fields and local friends do not establish actual online accounts.

UNKNOWN: Whether another application/repository implements authentication.

## 9. APIs / external services

VERIFIED: Local notification and sharing plugins, URL launcher, app/device information packages, Google Fonts. Settings offers a GoFundMe link and a mailto feedback link; these are external links, not an app backend. No runtime Bible API found. BibleVersions exposes KJV only.

VERIFIED: BibleService also contains a small hardcoded passage map used by the Quest Hub verse-of-the-day lookup, separate from the full KJV reader. A static check found all 30 current verse-of-the-day pool references directly represented in that map. This narrow success does not validate arbitrary passage lookup.

UNKNOWN: Font fetching/caching behavior in a fresh offline install. No font assets declared in pubspec; fonts are requested through GoogleFonts. Offline rendering needs observation.

## 10. Required environment variables / secrets

VERIFIED scope: No application .env files, runtime environment lookups or backend API-key configuration found in inspected application source/configuration. No runtime secret requirement established for core local functionality.

UNKNOWN: Apple signing/upload credentials and any tool-managed configuration outside Git. Record credential names/purposes when needed, never values. Dreamflow metadata contains project/account identifiers, which are not proof of authentication credentials.

## 11. Deployment / hosting infrastructure

VERIFIED: .replit installs Flutter via Nix and builds a release web bundle, then serves build/web with Python http.server on port 5000. Static deployment targets build/web. Replit is configured as a development/web hosting workflow; no runtime dependency on Replit was found in the mobile app.

VERIFIED: .dreamflow identifies project ebbfc591-935f-4f97-80c9-4cd604b32ea7 and a Dreamflow branch; its commit_id points to fdb0bf8, the parent of current HEAD. repository_id is blank. Git's latest commit modifies this metadata along with Flutter source. This proves Dreamflow involvement, not which service uploaded TestFlight.

UNKNOWN: Current Dreamflow/Replit project availability, active hosting or unpublished edits.

## 12. Apple / TestFlight configuration

VERIFIED: iOS display name Scripture Quest; bundle identifier com.scripturequest.app; pubspec version 1.0.1+9. CFBundleName retains dreamflow. kIsBetaBuild = true.

VERIFIED history: release-number edits progress through 1.0.1+3, +4, +5, +7, +8, +9. App icons were replaced in December; current asset-catalog filename checks found no missing referenced images.

USER-REPORTED: This app previously ran on iPhone and had live TestFlight distribution.

INFERENCE: Strong evidence this is a primary TestFlight-era mobile source repository: matching product, real iOS project, release-version history, beta flag, Dreamflow/Replit history and matching development timeframe.

UNKNOWN: Exact App Store Connect record/team, uploaded build numbers, corresponding commit, archive and signing state. No verified last-successful TestFlight commit. No uploaded binary or Apple build log was supplied.

## 13. Existing features

VERIFIED as source implementations, NOT runtime-tested: five-step onboarding; Quest Hub with today/tonight, reflection, weekly and event filters; KJV Bible reader and chapter completion; continue reading and verse of the day; journals, bookmarks, highlights, favorites; settings and reader preferences; XP, streaks, achievements, titles and book mastery; reading plans and questlines; local notifications; matching, verse scramble, book order, emoji parables and memorization screens; support/feedback and version information.

## 14. Partially implemented features

VERIFIED:
- ChapterQuizService seeds only John 3, Romans 8, Psalms 23, Proverbs 3 and Luke 2, including reflective questions. No expanded per-book quiz registry found in current tree or recovered historical filename inventory.
- Avatar equipment routes lead to a coming-soon screen; cosmetic purchases are disabled.
- Community screen is coming-soon; friend storage is local; legacy leaderboard service seeds bots and /leaderboards routes to personal Journey Board.
- Multiple task/quest systems coexist: TaskService/TaskModel, QuestBoardService/board Quest, QuestlineService, QuestProgressService and ProgressEngine.
- Broader translation/passages support in BibleService is sample content; selectable translation is KJV.

## 15. Broken features

No runtime failure VERIFIED: no Flutter build, analyzer, tests, simulator or device run attempted during this read-only phase.

Confirmed source/configuration concerns requiring validation:
- Incomplete native dependency lock (section 4).
- Root-route behavior does not match January commit's implied default-screen change (section 5).
- NotificationService initializes timezone data but never explicitly selects a device timezone. Scheduling correctness is UNVERIFIED.
- AppProvider contains one literal NUL byte inside a date regex at line 929; text-search tools treat the file as binary unless forced to text. Compiler impact UNKNOWN; no edit made.

## 16. Known technical debt / validation quality

VERIFIED: Large central provider, overlapping quest/screen systems, duplicate mastery screen paths and separate full-Bible/sample-passage access paths. architecture.md is an older plan; replit.md includes historical claims of passed tests and a web-only description despite the native projects. Treat both as context, not proof of current behavior.

VERIFIED: One Flutter test file contains 10 tests built from mock classes and miniature test widgets; it imports no Scripture Quest application files. These tests cannot validate the real reader/Quest Hub wiring. iOS RunnerTests contains an empty template test. No repository CI runs/releases found.

## 17. Missing information

Second repository content/access and relationship (URL now supplied); unsynced development; exact TestFlight version/commit; successful build logs and SDK versions; Apple signing/upload access; current runtime behavior; whether device-local data needs preservation/export before beta installation.

## 18. Current blockers

- No build-validation evidence yet; audit scope deliberately kept read-only.
- Flutter, Dart and xcodebuild were not found on PATH in this workspace. No toolchains installed as part of this task. Local iOS execution is not presently established; an Xcode-capable build environment must be identified for native validation.
- Cannot establish newest source across all locations until the second repository is compared.
- Cannot prove an exact TestFlight baseline without Apple build evidence or an equivalent retained archive/log.

## 19. Last known working state

USER-REPORTED: Functional iPhone app and live TestFlight before development stalled around January 2026.

VERIFIED source candidates: latest main ddd3412 (January 3) and its pre-January parent fdb0bf8 (build 9). Both are preserved in Git. Neither is yet a verified successful build. Do not reset or label either as known-good without further evidence.

## 20. Recommended recovery sequence

1. Compare the second repository read-only, if available, before choosing the authoritative development baseline. It is not a proven runtime dependency and is not required to keep investigating this checkout.
2. Correlate app version/build and bundle identifier with TestFlight/App Store Connect evidence when available; retain uncertainty if no exact source-to-upload mapping can be established.
3. Preserve selected baseline with a logical recovery checkpoint; prepare an isolated development branch for later repairs.
4. Identify/install a compatible Flutter toolchain using the existing dependency constraints, lockfiles and historical evidence. Do not blindly upgrade to newest dependencies.
5. Resolve dependencies in the isolated recovery checkout, inspect any lockfile changes, run analysis and a baseline build. Validate actual startup, local persistence, reader/chapter completion and quest progression.
6. On an Xcode-capable environment, resolve the native plugin set, inspect platform/signing requirements, build and test iOS. Distinguish simulator validation from signed TestFlight upload.
7. Repair only demonstrated blockers, verify results, then resume feature work with product decisions from the owner.

**Single best next action: provide access to ScriptureQuest/scripturequest or upload its source ZIP.** The supplied URL was checked but its code/history is not publicly retrievable. A ZIP enables a content comparison; full Git history would still require repository access or a Git bundle. No source-file homework is needed.

## Current state

WORKING: Public mobile source/history recovered; private repository ZIP inspected and compared. Core Bible asset is byte-identical across both snapshots. Runtime behavior remains unverified.
BROKEN: Current runtime UNKNOWN; existing source/configuration concerns remain documented above.
IN PROGRESS: Recovery audit complete enough to select a development baseline.
BLOCKED: Exact TestFlight commit/upload mapping and build environment remain unverified. Second-repository access no longer blocks source selection.
NEEDS FROM ME: Nothing further for this comparison. Apple/build access may be needed during native baseline restoration.
NEXT ENGINEERING ACTION: In a separately scoped restoration pass, preserve scripturequest-app at ddd3412, establish an isolated recovery branch/toolchain, and validate the existing app before feature changes.

## Activity / safeguards

2026-09-10, revision 001: Initial recovery brief recorded; awaited source.
2026-09-10, revision 002: Cloned public source; inspected all 90 commit subjects, key historical diffs, historical filename inventory, configurations, documentation, archived development-prompt evidence and major execution paths. Checked local imports, JSON structure, icon references and Git cleanliness. Queried public repository/release/Actions metadata. No app code edits, dependency installation/upgrades, builds, app execution, remote Git writes or deployment performed.

Archived prompts are historical requirements, not verified completion evidence or new authorization to modify the application. Existing recovery instructions and the owner's present scope remain authoritative.


## Historical second repository access attempt — revision 003 (superseded by ZIP comparison below)

Owner-supplied URL: https://github.com/ScriptureQuest/scripturequest

VERIFIED access checks:
- git ls-remote against the supplied URL failed with an authentication/username request in this unauthenticated environment. No source or Git history was obtained.
- GitHub public REST API GET /repos/ScriptureQuest/scripturequest returned HTTP 404.
- The same API check for ScriptureQuest/scripturequest-app returned HTTP 200, the returned private field was false, default branch main, pushed_at 2026-01-03T23:31:16Z.
- No applicable authenticated GitHub connector was exposed in the available tool registry.

A public 404 does not distinguish a private repository from a nonexistent, renamed, deleted or otherwise inaccessible repository. None of those explanations has been verified. Do not infer that the second repository is empty, older or unrelated.

| Comparison question | Verified result / limit |
|---|---|
| Newest repository | UNKNOWN across both repositories. scripturequest-app latest recovered commit is ddd3412, January 3, 2026; second repository history unavailable. |
| Most complete application | UNKNOWN across both. scripturequest-app contains the substantial Flutter/iOS application audited above; second repository contents unavailable. |
| Shared history or code | UNKNOWN; no second-repository objects or source obtained. |
| Important functionality absent from either | UNKNOWN; no cross-repository comparison possible yet. |
| Recommended source of truth | ScriptureQuest/scripturequest-app, PROVISIONAL, pinned to ddd3412778cf45206e6f9bddae9067c82866214b. It is the only verified recovered mobile application with history and native iOS configuration. |

Recommendation is based on recoverability and verified mobile-app contents, not a claim of proven superiority or recency over the inaccessible repository. Revisit before merging or discarding any alternative source. The exact TestFlight source revision remains unverified.

Revision 003 activity: performed read-only remote/API access checks and updated this document only. No builds, application modifications, migrations, merges, refactors or remote writes. Comparison remains blocked by unavailable second-repository contents.


## Completed private ZIP comparison — revision 004, 2026-09-10

This section supersedes the revision 003 access blocker and provisional recommendation. Earlier inventory statements that the second repository's contents are unknown are historical; its supplied snapshot is now inspected. Its full Git history and any changes outside this ZIP remain unknown.

### Artifact identity and method

VERIFIED: Owner supplied scripturequest-main.zip as an export of ScriptureQuest/scripturequest. Inspected at /workspace/scratch/e33aa9ed0a1d/upload/scripturequest-main.zip and extracted without source edits under /workspace/scratch/e33aa9ed0a1d/comparison/scripturequest-main.

- ZIP SHA-256: 1f5ba919a6230974fcd61a2be0ce6496ca4d760da4cfd0d649d3e1f46b594238.
- ZIP comment: f76599f8bf3c1382eb71a41dc236c1b642422736. This is an archive-provided revision identifier, not independently authenticated Git history. This commit object is not present in the recovered public history.
- No .git directory included; no private commit dates, parents, branches or ancestry can be proven from the ZIP.
- Compared application file bytes against public HEAD and historical Git blobs; inspected differing source against the initial public snapshot. No builds, dependency resolution, migrations or source edits.

### Verified comparison

| Area | Private scripturequest ZIP | Public scripturequest-app |
|---|---|---|
| Declared version | 1.0.0 | 1.0.1+9 |
| Application Dart files under lib | 141 | 142 |
| Shared code | 133 of 141 exactly match public initial commit 81ac6c7; 121 exactly match public HEAD | Preserves that earlier code plus later development history |
| Bible dataset | Byte-identical to public assets/bible/kjv.json | Same full bundled KJV dataset |
| Quest Hub screen | No quest_hub_screen.dart | Present and selected by root route |
| Later development | Earlier onboarding, reader, task and UI behavior | December quest targeting/anti-repetition, reader/onboarding revisions and January task-screen changes |
| Feedback dependencies | No url_launcher, package_info_plus or device_info_plus direct dependencies | All three declared |
| Build evidence | README says “Source code repository for Codemagic builds.” Includes generated iOS files | Dreamflow metadata, Replit configuration, iOS project and release-version history |
| Git history available | None in ZIP | 90 commits through January 3, 2026 |

VERIFIED: The ZIP also duplicates the application source folders at repository root. Every comparable root/lib Dart pair is byte-identical. These duplicates are not additional functionality. pubspec and generated configuration identify lib/main.dart as the application entry point.

### Unique material and important differences

Eight private lib files have no identical same-path blob in the recovered public history: achievements_screen.dart, profile_screen.dart, home_screen.dart, verses_screen.dart, main_navigation.dart, settings_screen.dart, matching_game_screen.dart and app_provider.dart. Inspection shows earlier presentation/behavior compared with the initial public snapshot:
- Earlier achievement presentation without the later progress-bar/tile treatment.
- A Profile support card links to /support. Public source instead provides support/GoFundMe controls in Settings; the /support screen remains present. This is a UI difference, not a missing donation backend.
- Earlier home featured-verse selection, before the public daily rotation/streak-card changes.
- Reader/progression before the public reading-time gating additions.
- Earlier navigation/achievement-overlay behavior and matching-game fallback text/logging.

No substantial private-only application subsystem or feature requiring a merge was identified in this comparison. Shared services, quizzes, models, assets and reading features do not provide a newer alternative implementation in the ZIP. Both snapshots still have the five-chapter quiz set.

ZIP-only supporting material includes a Codemagic README, generated native plugin registrants, Generated.xcconfig, flutter_export_environment.sh, generated debugger helpers, android/local.properties and older icon assets. Generated iOS settings refer to /flutter/sdk and /hologram/data/workspace/project, with version fields 1.0.0. These are environment-specific build clues, not a portable validated pipeline. No codemagic.yaml, Fastlane setup or equivalent Codemagic build recipe was found. README alone does not prove a successful Codemagic or TestFlight build.

### Decision

**Recommended source-of-truth development repository: https://github.com/ScriptureQuest/scripturequest-app**

**Initial recovery revision: ddd3412778cf45206e6f9bddae9067c82866214b (main).**

INFERENCE supported by exact file matches and source differences: scripturequest-app represents the more advanced and more complete mobile application among the two supplied snapshots. The private ZIP appears to be an earlier build/export copy of the same application, not a newer replacement.

Shared code is VERIFIED. Shared Git ancestry and exact chronological order of private commits are UNKNOWN because the ZIP has no Git history. The recommendation does not depend on establishing those facts: the public repository contains the later functional changes, higher declared version and recoverable development history. No further private Git investigation is necessary to choose this baseline.

Keep the ZIP as historical evidence, particularly its Codemagic clue; do not merge generated files or duplicated root source into the selected app. No repository was deleted, changed, merged, built or pushed during this comparison. The public checkout remains clean.

### Remaining unknowns and next action

Exact TestFlight build/commit, Apple signing/upload details, Codemagic account/project configuration and successful present-day builds remain unverified. Unprovided branches or unsynced edits cannot be ruled out.

**Single best next action: restore and validate the existing scripturequest-app baseline in an isolated recovery branch, with a compatible toolchain and minimal repairs only if demonstrated necessary.** This comparison task stops at the recommendation; no restoration work was begun.


## Preview/testing workflow investigation — revision 005, 2026-09-10

Source-of-truth scripturequest-app is now owner-confirmed. No repository files changed, no tools installed, no preview registered/configured/deployed, and no build attempted in this investigation.

VERIFIED infrastructure and code findings:
- This execution workspace is Linux x86_64 and advertises the managed Linux Sites execution profile. Its documented preview capability is internal agent QA only, with no user-facing local-server handoff. Do not promise that a localhost URL or internal agent browser can be opened by the owner.
- Sites creation/private deployment tools are exposed and Sites supports static output. This establishes a possible delivery mechanism for compiled Flutter Web assets, not a verified successful Scripture Quest preview. Flutter SDK availability/downloads, dependency compatibility, build success, output packaging and account hosting limits remain to be validated. Source remains in scripturequest-app; a preview deployment must not become an independently edited replacement application.
- Existing web/index.html bootstraps Flutter, uses a root base path, and removes splash on Flutter's first frame. Existing Replit configuration already builds/serves web assets. No web conversion or language rewrite is indicated.
- AppProvider guards native device-info Platform calls with !kIsWeb and provides a web branch. SettingsProvider still initializes NotificationService during startup. Notification errors are caught; actual browser startup and native-feature handling remain untested.
- Browser storage will represent separate test data from the native iPhone installation. A stable preview origin should be retained between revisions; do not assume web and native progress synchronize.
- Flutter documentation states web hot reload is enabled by default starting in 3.35. This repository's historical 3.32 documentation does not establish that capability for its restored toolchain. A published static build requires rebuild/deployment and browser refresh regardless of hot-reload support.
- Codemagic officially offers interactive browser iOS simulator/Android emulator previews. These require compiled artifacts; currently teams only, pay-as-you-go trial 100 preview minutes then $0.095/min, maximum 20-minute sessions. This is separate from individual free build minutes. It is not a physical iPhone and not a source-level live-edit preview.
- Codemagic documents automatic App Store Connect/TestFlight publishing. Individual plan advertises 500 free macOS M2 build minutes/month, then $0.095/min; eligibility/current account plan unverified. Apple Developer membership is $99/year in USD; owner's current membership/signing status unverified.
- No authenticated control of the owner's PC, GitHub writes, Codespaces or Codemagic account has been established. Agent can prepare code/configuration here; operating an external build service requires approved account access and supported API/automation. The owner must perform sign-in/credential authorization when required.

RECOMMENDED (not configured): everyday hosted Flutter Web build at a stable private preview URL, initially using available Sites static-hosting capability if build/output compatibility is proven. Agent performs technical edits, builds and preview updates; owner opens/refreshes the link and supplies screenshots/behavior feedback. No Replit/Dreamflow AI subscription is inherently needed. Hosting cost/limits are not verified, so do not promise unlimited free hosting. Work usage remains applicable. Native code remains canonical in scripturequest-app.

RECOMMENDED native validation: Codemagic macOS signed builds to TestFlight, initially internal testing for the owner, after coherent changes rather than every visual tweak. Owner installs/updates on iPhone; agent handles build troubleshooting as access allows. No Mac purchase required for this route. Apple processing/review times are variable, and old TestFlight builds expire after 90 days.

Alternatives evaluated: local Flutter browser development (fast, no added SDK fee, but this chat has no PC control); local Android emulator (native Android validation, heavier setup, not iOS); local iOS simulator (requires Mac/Xcode, not available here); Codespaces (interactive forwarded web ports, account/startup/usage overhead, external agent access unestablished); Codemagic paid browser simulator (higher iOS fidelity, build waits and metered sessions). None improves simplicity enough to replace hosted web plus real-iPhone TestFlight for the current owner/workspace.

Timing expectations are estimates, NOT benchmarks: warm development reload seconds; hosted web build/update usually minutes; native cloud build/upload/processing tens of minutes or longer. First restoration may take substantially longer.

Sources checked:
- https://docs.flutter.dev/platform-integration/web/building
- https://docs.flutter.dev/tools/hot-reload
- https://docs.flutter.dev/platform-integration/ios/setup
- https://developer.android.com/studio/run/emulator
- https://docs.github.com/en/codespaces/developing-in-a-codespace/forwarding-ports-in-your-codespace
- https://docs.github.com/en/billing/concepts/product-billing/github-codespaces
- https://docs.codemagic.io/yaml-distributing/app-preview/
- https://codemagic.io/pricing/
- https://docs.codemagic.io/yaml-publishing/app-store-connect/
- https://developer.apple.com/testflight/
- https://developer.apple.com/programs/enroll/

CURRENT STATE: preview milestone COMPLETE by owner confirmation. Owner established an interactive Flutter Web preview in GitHub Codespaces from ScriptureQuest/scripturequest-app and personally clicked through it; most existing functionality appears to work. This is owner-reported validation, not an agent-observed full regression test. Earlier workspace build blockers below are historical and must not trigger renewed infrastructure investigation.

## Preview execution checkpoint — 2026-09-11

VERIFIED: checkout is on `recovery/web-preview`, based on `ddd3412778cf45206e6f9bddae9067c82866214b`. App Dart source, iOS files, pubspec.yaml and pubspec.lock remain unchanged. Added only preview tooling: package.json/package-lock.json (Vite 8.0.13), vite.config.js, scripts/build-web-preview.sh, WEB_PREVIEW.md, generated-output ignores, and .openai/hosting.json. No new source commit or push yet.

VERIFIED: private Site already registered as `appgprj_6aa21610399c819181da028365043993`, slug `scripture-quest-preview`, owner-only, no saved/deployed version. Reuse this Site; do not create another.

VERIFIED: Flutter 3.35.7 bootstrapped successfully but its SDK pins (vector_math 2.2.0/test_api 0.7.6) do not match the app lockfile. Selected official Flutter 3.32.8, whose SDK pins match vector_math 2.1.4/test_api 0.7.4/meta 1.16.0. SDK checkout: /workspace/scratch/e33aa9ed0a1d/toolchains/flutter, tag 3.32.8, commit prefix edada7c5. Matching SDK download completed; its tooling package resolution was still running when execution transport disconnected.

VERIFIED environment accommodations: CI=true skips Flutter's Azure metadata probe (the original request was rejected by automatic security review); TAR_OPTIONS=--no-same-owner avoids SDK archive ownership extraction failure. Neither changes native app behavior. A stale partial SDK ZIP failed validation; official installer removed it and a clean download completed.

WORKING: source recovery, safe branch, private Site registration, npm preview dependencies installed.
BROKEN: no application defect established; previous workspace transport interruption recovered.
IN PROGRESS: completing Flutter 3.32.8 build artifacts and app package resolution. Dart SDK 3.8.1 is present. The direct Flutter-tool package get completed successfully (session 12703); detailed log is flutter-3328-pub.log. Direct app `dart pub get` failed because it did not recognize the Flutter SDK; use `flutter pub` after tooling setup. The subsequent Flutter command (session 21158) advanced into sky_engine download.
BLOCKED: on resumption, session 21158 returned the explicit policy error `Network access to "https://storage.googleapis.com:443" was blocked by policy.` Do not bypass this restriction using mirrors, alternate download tools, or network paths. Local inspection confirms bin/cache/flutter_web_sdk is absent, app .dart_tool/package_config.json is absent, and no build/web/index.html exists. A sky_engine ZIP is cached under the correct 3.32.8 engine ef0cd000916d64fa0c5d09cc809fa7ad244a5767, but its completeness has not been validated. No successful app web build or browser launch yet.
Historical next action (superseded): complete workspace build components and hosting. Owner has since completed the preview milestone in Codespaces; do not pursue this action.

## V2 product/design assessment — pending owner approval

Scope: read-only assessment of recovered checkout ddd3412778cf45206e6f9bddae9067c82866214b. No app code, dependency, or preview configuration changes in this assessment. Codespaces exact commit, any local changes, screenshots and native-device results were not supplied; visual polish judgments are inferred from source, not a claimed live visual inspection.

VERIFIED source findings:
- Active navigation is three tabs: Quest Hub, Bible, Profile. Reading plans and learning games also appear under Community. Profile's expandable Explore section is labeled Coming Soon despite containing working feature links.
- Active onboarding comprises six beta pages: welcome, beta notice, reading comfort, rhythm, identity, closing. The separate older personalized flow exists but is not treated as the active default flow.
- App theme packs derive from darkTheme with Orbitron headings and Rajdhani UI typography; reader separately supports Lora/Inter and paper/sepia/night.
- Quest Hub puts greeting, full daily verse and Continue Reading ahead of Today/Weekly/Reflection/Events lists, with generic empty messages.
- Guided quest Journey through John covers John 1, 3 and 20; reading plan Journey Through John covers John 1–12. Seven reading-plan seed definitions exist. These are distinct content/progress systems with overlapping presentation.
- Reader completion eligibility uses a 12-second presence gate plus engagement conditions, while daily/weekly quest progression also checks a 45-second threshold. The reader shows chapter completion feedback even when the quest threshold is unmet.
- ProgressEngine chapter completion awards 10 XP; UI emits this from the completion handler. Repeat-completion/idempotency behavior merits focused validation, not an assertion of reproduced exploitation.
- ProgressEngine directly requests quiet_reflections_5 and night_scholar_5 unlocks on corresponding individual task events; unlockIfNeeded itself checks only existing unlock status and does not check the five-task count. This is a source-confirmed requirement-enforcement gap in that path; it was not runtime-reproduced.
- Profile uses level-derived faith titles including Faith Champion. Multiple reward channels (snackbar, achievement/quest overlays, book-reward modal, reader banner) coexist.
- Long-press verse tools, local journal search/tags/pinning, offline Bible, reader preferences, guided quests and plan tracking are assets to preserve. Accessibility risks include custom gesture chips, fixed-height sticky filters and RichText without an explicit system text scaler; device/screen-reader testing remains unperformed.

RECOMMENDED direction (not approved): a calm guided Scripture-reading experience with one clear next reading, optional reflection, meaningful learning milestones and forgiving habit support. Preserve Flutter, offline Bible, existing progress/history and working services. Recommended final navigation: Today, Bible, Journeys, My Journal. Bring plans and guided quests into one discovery surface without first merging storage models. Keep XP secondary and use descriptive reading accomplishments instead of spiritual-ranking labels.

Recommended FIRST implementation pass (not authorized): a bounded Today/Quest Hub makeover, reader visual/control consistency, and existing navigation/header styling; scoped reusable typography/color/card/action components. Retain current three destinations initially. Preserve quest generation, XP calculations, completion rules, storage keys, onboarding, plan/questline engines, and games in this visual pass; log behavior defects for a separate core-experience repair pass. Validate new/returning/completed/empty states, small iPhone layouts, larger text, reading return navigation, and persistence before completion.

WORKING: owner-tested Codespaces Flutter Web preview; most existing functionality owner-reported working.
BROKEN: source-confirmed reward requirement gap and completion-rule inconsistency; runtime impact not yet reproduced by agent.
IN PROGRESS: owner review of V2 direction and proposed first makeover pass.
BLOCKED: implementation intentionally awaits product/design approval.
NEEDS FROM ME: approve or revise V2 direction; no infrastructure work requested.
NEXT ENGINEERING ACTION: after approval, implement only the agreed first pass on a safe checkpoint from the actual current source-of-truth state, preserving the working Codespaces loop.

## V2 first implementation — committed review candidate

Owner authorized implementation of Quest Hub/Home and Bible Reader, then commit
and GitHub push. This supersedes the assessment's pending-approval state.

VERIFIED:
- Local branch `v2/reading-design`; checkpoint `v2/pre-reading-design` at
  ddd3412778cf45206e6f9bddae9067c82866214b.
- Commit `6700909b56d837ca8b3f51ae113a13a2c3939622` contains seven UI source
  files plus V2_READING_PASS.md. Old preview scaffold changes remain uncommitted
  and are excluded from this delivery.
- Today foregrounds one existing reading quest with continuation/completed
  fallbacks, secondary reflection and expandable optional quests. Reader uses
  shared reading presentation, visible passage/settings controls, tap verse
  actions, system text scaling and inline chapter completion.
- Reflection sheet now scrolls with the keyboard. Existing providers, services,
  models, assets, dependency manifests/lockfile and native projects are unchanged.
- Ten existing reading/quest method blocks match baseline ignoring whitespace,
  commas and comments; source diff check passes and Dart formatting parses edits.
- Final full-library analysis after package restoration reports ZERO ERRORS,
  with 123 warnings/information diagnostics. An initial rerun failed on missing
  dependencies; this is superseded by v2-final-analysis.log. Lockfile unchanged.
- Attempted test run stopped before executing: cached Flutter tool snapshot
  version mismatch. No tests claimed passed; do not redo Codespaces setup.
- No Flutter Web compilation, runtime widget test or visual/device inspection of
  this design has been completed. These remain acceptance gates.
- Actual GitHub push failed: could not read Username for https://github.com with
  terminal prompts disabled. No GitHub authenticated connection is available.
- Verified portable Git bundle Scripture_Quest_V2.bundle contains the exact
  commit and requires the recovered baseline commit already in the repository.

WORKING: owner-established Codespaces preview; locally committed V2 UI candidate.
BROKEN: no new runtime defect established; final runtime validation outstanding.
IN PROGRESS: delivery and validation of first V2 pass only.
BLOCKED: GitHub push authentication; local Flutter test-tool snapshot mismatch.
NEEDS FROM ME: authenticated GitHub access, or import supplied Git bundle in the
existing Codespace to test the exact committed changes.
NEXT ENGINEERING ACTION: validate this commit in the existing Flutter environment,
resolve only introduced issues, push once authentication is available, and await
owner review. Do not start Phase 2 or investigate preview infrastructure.

## Master V2 roadmap and quality audit — September 11, 2026

Supersedes earlier push blocker: remote `v2/reading-design` independently verified
at `6700909b56d837ca8b3f51ae113a13a2c3939622`. Owner confirms the first V2 pass is
running successfully in Codespaces. No further preview work required.

Created Scripture_Quest_V2_Master_Roadmap.md as the consolidated planning draft.
It preserves meaningful gamification and distinguishes source facts, owner-tested
preview success, historical plans, deferred work and new recommendations.
Historical exact Quest System v1 implementation claims are not assumed to match
the current multiple-system checkout; discrepancies are recorded explicitly.

Read-only quality checks: Bible asset 66 books, 1,189 chapters, 31,102 nonempty
verses; numbering and canonical chapter counts passed. Thirty-four literal guided
reading references passed bounds checks. Nine guided quest definitions and seven
reading plans exist; NT/90 generation produces 87 steps. No full trusted-text diff,
new build, runtime test or device audit claimed.

Source-confirmed concerns documented with Q01–Q18 IDs: incorrect red-letter speech
attribution, mixed game text, repeat completion/reward paths, achievement count
bypass, one-level-per-grant handling, journal corruption overwrite path and
schedule/content inconsistencies. Accessibility, persistence edge cases, routing,
background timing and state transitions have explicit pending acceptance tests.

PROPOSED sequence, awaiting owner review: (1) Scripture and progress integrity;
(2) connected journeys and visible accomplishment; (3) Learn/Codex and purposeful
custom graphics. Further personal-content/accessibility and release passes follow.
No app source changed; no automatic rewrite or Phase 2 implementation authorized.

CURRENT STATE: WORKING—owner-tested V2 preview, committed remote branch.
BROKEN—source-confirmed quality issues in master roadmap, runtime impact not fully
reproduced. IN PROGRESS—roadmap review. BLOCKED—no planning access blocker.
NEEDS FROM ME—review proposed roadmap. NEXT ENGINEERING ACTION—Pass 1 only after
approval; preserve existing Flutter, data, earned history and preview workflow.

## Pass 1 integrity implementation — September 12, 2026

VERIFIED: source of truth remains `ScriptureQuest/scripturequest-app`, existing branch `v2/reading-design`, based on `6700909`. Safety checkpoint `checkpoint/pre-pass1-6700909` preserved. Approved Master Roadmap and product guardrails govern this pass; no Pass 2 or redesign work performed.

VERIFIED: targeted repairs cover exact sourced red-letter spans, chapter/task reward replay protection, five-task counts, multi-level XP, journal corruption/loading safeguards, qualified reread consistency, 14 corrected KJV game passages and a true 90-day NT schedule. Existing `plan_nt_90` keeps its exact 87-step references; new starts use `plan_nt_90_v2`. Underlying Bible asset, iOS project and dependency files are unchanged.

VERIFIED: 28 automated tests pass, including 18 new tests against production services/providers, concurrent replay, saved-state reload, failed writes, exact red-letter span rendering and schedule preservation. Content checker passes 66 books / 1,189 chapters / 31,102 verses and 14 exact game passages. Static analysis has zero errors, with the same 98 warnings and 26 infos as baseline and no new diagnostics. Importer regenerates the exact map/report from the pinned eBible KJV archive.

VERIFIED ENVIRONMENT: Flutter target remains 3.32.8 / Dart 3.8.1. Missing locked package caches were restored into the workspace. Mixed-version cached compiler/test SDK artifacts were replaced with artifacts from existing engine `ef0cd000916d64fa0c5d09cc809fa7ad244a5767`; no app SDK/dependency upgrade. Test execution now works. No preview infrastructure investigation or deployment was performed.

UNVERIFIED / LIMITS: 19 source-text mismatches stay uncolored and are listed for trusted-content review. Full Bible text certification, complete cross-store crash atomicity, multi-tab concurrency, legacy board persistence, modal reading timing, DST/timezone, native iPhone and VoiceOver validation remain outside the proven result. Existing prior audit findings are retained in the approved roadmap.

CURRENT STATE:
WORKING: baseline Codespaces preview (owner verified); repaired scoped integrity behavior (automated tests).
BROKEN/OPEN: documented trusted-content/release-review items; no newly introduced analyzer errors.
IN PROGRESS: Pass 1 delivery and owner review.
BLOCKED: direct Git push may still require bundle handoff; delivery result recorded below.
NEEDS FROM ME: test/review Pass 1 before any Pass 2 authorization.
NEXT ENGINEERING ACTION: address review findings only; stop after Pass 1 handoff.


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


## Pass 3 handoff — 2026-09-14

VERIFIED baseline: approved Pass 2 `f6c9a57561ba54ae6c7ae9d40ba5e23dbdab1fec`, same `v2/reading-design` branch and Flutter 3.32.8. Pass 3 adds passage-linked Codex/learning/recall records in `exploration_v1_<user id>` using existing local storage. It does not migrate Journey, journal, Bible, saved-plan, legacy-memory, or user reward data. Quiz completion uses additive pending-result keys and existing reward/stat receipts. The older Shepherd proof is retained with its earning context.

Four discoveries, four bounded Connections, three vector landscape variants, honest remembering outcomes, and new Learn/You/Board links are implemented. New-period learning quests reuse an existing slot; saved quests and their rewards remain unchanged. No backend, deployment, package, SDK, or Apple configuration changes.

Validation: 54 tests including all Pass 1/2 tests; zero analyzer errors/no new diagnostic identities; release Flutter Web build; actual Flutter widget navigation, phone/desktop renderings, large text/night setting, persistence and reward replay checks. Details and exact acceptance steps: `docs/PASS3_EXPLORATION_AND_MEMORY.md`. Browser/Codespaces and native-device acceptance are not claimed from this workspace.

The 19 unmatched red-letter verses still await trusted-content review. No Scripture data guesses were made. Future themes, larger content/art libraries, universal old-game audit and fuller personal history remain deferred in the Master Roadmap. Preserve unrelated preexisting preview/configuration files outside the Pass 3 commit. Stop for Zeb’s Pass 3 review before any later phase.


## Pass 4 handoff — 2026-09-16

VERIFIED: continued on `v2/reading-design` from Pass 3 `378926bdedf82453ca63fe70d030a6206813ab74`. Scripture Light is retained and Scripture Dark is implemented through a shared theme registry/semantic palette. Appearance uses the additive `scripture_appearance_v1` key, independently of progression data, and preserves existing reader preferences. No infrastructure, Flutter/dependency, iOS, Bible-data or progress-service changes were made.

Learn, Play & Learn, Achievements, You and important personal-library screens now share the evolving V2 presentation. Journey Board/Codex/Connections/remembering and Daily/Weekly/XP systems are retained. Legacy compatibility boundaries preserve untouched routes; older cosmetic preview integration remains staged work.

VERIFIED validation: all 62 tests pass; analyzer 0 errors, 92 warnings and 26 infos with no new diagnostic identities; production Flutter Web build succeeds. Both themes have 88 screen/size render checks, large-text control checks, connected discovery/learning/remembering navigation and real John 3 red-letter rendering assertions. Detailed scope, acceptance walkthrough and limits are in `docs/PASS4_THEMES_AND_PRODUCT_COHESION.md`.

UNVERIFIED/deferred: real browser/Codespaces and native iPhone/VoiceOver acceptance, the reported Journey/45-second qualification concern, the 19 unmatched red-letter verses requiring trusted review, and unrelated legacy issues. No comprehensive bug hunt or new-game expansion was undertaken. Preexisting preview/configuration working-tree changes remain excluded from this delivery. Stop for Zeb's Pass 4 review.
