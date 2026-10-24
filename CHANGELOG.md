# Changelog

## 0.1.0 (unreleased)

- Add Nextcloud Login Flow v2 and multiple account selection.
- Store account metadata in SQLite and app passwords separately in secure storage.
- Remove local account data and attempt server-side token revocation on account removal.
- Cache boards, stacks, and cards; show cached content when a refresh fails.
- Reject late cache writes from removed or reauthenticated accounts.
- Add Czech and English text for the initial account and board screens.
- Save card creation and edits in a persistent outbox before sending them.
- Preserve both versions of conflicting edits and require a decision for uncertain writes.
- Add a card editor for titles, descriptions, due dates, and supported completion fields.
- Prevent an older refresh response from overwriting a confirmed write.
- Autosave card editor drafts separately from the server outbox and restore them after restart.
- Refresh after resuming or changing networks; poll opened boards only in the foreground.
- Create, edit, archive, delete, and restore boards through the durable outbox.
- Create, rename, reorder, and delete columns with board management permission.
- Resolve offline parent-child creation dependencies without guessing server IDs.
- Move cards through a destination picker, reorder them with drag handles, and archive, restore, or delete cards.
- Assign existing board labels and users from a live card detail view.
- Render Markdown without fetching external images automatically.
- Persist accepted card actions before reading their results, so read-back failures do not resend mutations.

Automated and device acceptance tests are scheduled after feature development. This version has not been distributed.
