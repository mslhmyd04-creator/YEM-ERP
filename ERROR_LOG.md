# Error log

| Date | Phase | Command | Error | Cause | Fix | Result |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-09-28 | 0 | `command -v flutter; command -v dart` | Neither SDK is installed in this workspace | Build tools unavailable | Prepare source and exact commands for an equipped machine | OPEN: build and tests NOT VERIFIED |
| 2026-09-28 | 0 | GitHub Actions `flutter analyze` | Generated `test/widget_test.dart` refers to nonexistent `MyApp` | `flutter create` supplies its sample test when the project has no widget test | Added a project-specific RTL widget test before generator runs | RESOLVED: analyze, tests and Android debug build passed in run 36461872576 |

- 2026-09-30 / run 36750927546: analysis reported five style/deprecation diagnostics; added braces and replaced sqlite3 dispose with close. Verification pending next CI run. Windows authentication/migration tests passed.

- 2026-09-30 / run 36751478835: UI Scaffold missed closing Align parenthesis; corrected before rerun.

- 2026-09-30: Both authentication diagnostics and UI parenthesis errors RESOLVED; run 36752011534 analysis, tests, Android/Windows debug builds and uploads PASS.

- 2026-10-05 / Phase 0: no application analysis/test/build failures in master and branch increments. Git metadata /git/commits read returned transient internal error; /commits read provided the tree successfully (RESOLVED). Native verification PASS in 37335012029; local SDK remains unavailable.

- 2026-10-05 / Phase 0 / run 37337178600: analyzer unawaited_return_in_try_block on generic synchronous transaction in async user save. Specify transaction result as String so it cannot infer a Future result. CI recheck pending.

- 2026-10-05 / Phase 0: administration Flutter tests exceed expected runtime on both runners; add expanded test reporting and a two-minute per-test timeout to identify blocked test. Diagnosis pending CI; do not add features before verification.

- 2026-10-05 / run 37338775503: 34 Flutter tests passed, one role/user widget assertion failed after a missed CheckboxListTile tap; next widget test did not finish. Add a settled frame after scrolling, bounded pumpAndSettle and checkpoints to diagnose remaining wait. Verification pending.

- 2026-10-05 / run 37339491809: diagnostic test used named pumpAndSettle timeout; Flutter API takes positional duration/phase/timeout. Corrected against official WidgetTester API. CI recheck pending.

- 2026-10-05 / run 37339837101: focused text field scrolled back over revealed checkbox; following test blocked before initial form setup. Move migration/bootstrap fixtures to setUp outside FakeAsync, unfocus before reveal/tap and assert hit testing. Recheck pending.

- 2026-10-05: Administration analyzer, scroll/focus and blocked second widget fixture issues RESOLVED in 37340719874; all 36 Flutter tests pass on both runners, analysis and both builds PASS. SQL checks PASS.

- 2026-10-05 / run 37342448506: analysis and 43 Flutter tests passed; legacy administration upgrade fixture already contains finance permission definitions, so migration 006 INSERT raised permissions.code duplicate. Use INSERT OR IGNORE as in other permission migrations and retain pre-existing definitions in the migration regression fixture. Verification pending.

- 2026-10-05: Duplicate financial permission migration error RESOLVED in 37342842602; all 44 Flutter tests, 13 SQL checks, analysis and both native builds PASS.

- 2026-10-05 / Phase 0 / local SQL checks: migration 007 initially placed table CHECK before later columns, causing SQLite syntax error near journal_entry_id. Move table constraints after all column definitions. RESOLVED in local SQL checks; native recheck pending.
