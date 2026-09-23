# Post-Pass-5 startup storage fix

Baseline: `23a8e666e9cf219cef03910120383c7ccc67e1c7` on `v2/reading-design`.

## Verified root cause

`main.dart` creates SettingsProvider and AppProvider independently. Both initialize asynchronously and both await StorageService.getInstance(), directly or through SettingsService. AppProvider correctly awaits that factory before constructing UserService and calling loadData().

The factory previously assigned `_instance` **before** awaiting SharedPreferences.getInstance(). A second caller observed that instance and returned immediately while `_prefs` was still null. If Settings started the load, AppProvider could receive unfinished storage, read current_user as null, attempt default-user creation, and fail saving it with `Bad state: Storage not initialized`. initialize() then never reached the flags that end Today’s spinner. This matches the supplied browser stack and was reproduced in a cold-isolate test. The same factory code exists in Pass 4: this is a preexisting race exposed by live startup, not an intentional Pass 5 behavior change.

The inverse ordering can affect settings. All services given the unfinished instance can be affected; other tabs being navigable does not prove their user-backed data loaded correctly. Today makes the failure particularly obvious because it waits for provider readiness.

## Repair

StorageService owns a shared initialization Future. Every caller awaits it. The private instance is constructed and returned only after preferences are loaded. Successful calls reuse the same completed Future and instance. On failure, the error propagates to all waiting callers; clearing only the failed Future permits a later explicit retry. No data is cleared or rewritten by initialization. No delay, swallowed exception, consumer-specific initialization or provider rewrite was added. Existing save/receipt/journal safeguards are untouched.

Only production change: `lib/services/storage_service.dart`.

## Tests and evidence

- `test/integrity/storage_startup_test.dart`: cold platform store held behind a Completer; Settings starts first, then a direct current_user consumer and AppProvider. Proves no consumer obtains storage or writes before release; verifies one platform load, both providers finish, Today’s loading flag clears, existing user ID/XP/reward receipt and a history sentinel survive. This test failed on the original code with the same before-init/current_user and save exceptions as the browser.
- `test/integrity/storage_startup_retry_test.dart`: all concurrent waiters receive a real load failure; a later retry succeeds and preserves original bytes; subsequent calls reuse readiness.
- Full suite: **75 tests passed**, including all 73 previous tests and Pass 1–5 integrity/UI protections.
- Analyzer: **0 errors, no new diagnostics**; 92 preexisting warnings and 26 preexisting infos remain.
- Production Flutter Web: successful using existing Flutter 3.32.8 and `--no-pub --no-tree-shake-icons`. No SDK/dependency changes.
- Final diff scoped to storage initialization, two tests and documentation. Existing preview/configuration changes excluded.

The earlier suites initialized storage before constructing providers; this meant they did not exercise concurrent cold startup. The new test deliberately does not warm storage in setup and controls platform readiness without a production delay.

## DWDS warning

Inspected the installed Dart SDK `lib/_internal/js_dev_runtime/patch/developer_patch.dart`. `_registerExtension` emits the named console warning when debugger hooks are absent, then returns. Its message names the DWDS-supported development environment. That branch is separate from preferences and the app storage lifecycle; the storage failure reproduces in a native Flutter test without DWDS. No production modification is justified for this tooling warning. The exact full browser warning was not provided, so this conclusion concerns the reported registerExtension/DWDS warning family.

## Acceptance boundary

The race is reproduced and fixed with controlled cold-start concurrency; full regressions and the release Web build pass. A fresh Firefox/Codespaces reload of the delivered fix remains live-browser confirmation, not claimed performed here. Do not clear browser storage to test this fix. No Pass 6, broader bug hunt or unrelated refactor was undertaken.
