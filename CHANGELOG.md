# Changelog

## 0.1.0 (2) - 2026-10-25

Submitted to Google Play closed testing (alpha); awaiting Google review.

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
- Add paginated comments, replies, author-only editing and deletion, and recoverable comment drafts.
- Use the server user ID for comment ownership instead of inferring it from the login name.
- Search Deck recipients and manage user, group, team, and federated board sharing.
- Recheck sharing rights before sending; distinguish share permission from management permission.
- Create, rename, recolor, and delete labels, including dependent offline assignments.
- Edit and restore card start dates and custom colors on supported servers.

- Add file uploads, downloads, exports and links to existing Nextcloud files.
- Add local and server search, task filters and links to individual cards.
- Add card copies, related cards, done columns and in-app notifications.
- Preserve server retry delays across restarts and resume queued changes from the board list.
- Match suite sign-in screens, add OwnDeck launcher icons and fix keyboard handling in landscape dialogs.
- Add optional CI-configured Sentry and Rybbit with separate persistent opt-out switches.
- Use system file-picker grants without broad media, storage or microphone permissions on Android.

Automated and Android device checks run during development. See `docs/testing.md` for tested revisions and limits. Google Play tester availability depends on review approval.
