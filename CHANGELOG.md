# Changelog

## 0.1.0 (unreleased)

- Add Nextcloud Login Flow v2 and multiple account selection.
- Store account metadata in SQLite and app passwords separately in secure storage.
- Remove local account data and attempt server-side token revocation on account removal.
- Cache boards, stacks, and cards; show cached content when a refresh fails.
- Reject late cache writes from removed or reauthenticated accounts.
- Add Czech and English text for the initial account and board screens.

Automated and device acceptance tests are scheduled after feature development. This version has not been distributed.
