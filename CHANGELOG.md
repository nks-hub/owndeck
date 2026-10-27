# Changelog

## 0.1.4 (7) - 2026-10-27

Google Play closed testing (alpha) and TestFlight.

- Error reports carry the readable error text and the full stack trace; sign-in credentials are removed before sending.
- Flutter errors without app frames keep the framework frames.

## 0.1.3 (6) - 2026-10-27

Google Play closed testing (alpha).

- Keep a due date reminder that is late because Android delivers inexact alarms with a delay.
- Fix a crash at start on iOS when background sync is scheduled for the first time.

## 0.1.2 (5) - 2026-10-27

Google Play closed testing (alpha).

- Redesign the sign-in screen: the server field and actions come first, in the app's colors.
- Redesign card tiles: label pills, color band, assignee avatars and one metadata row.
- Pick any custom color for cards, boards and labels, with presets as quick picks.
- Select several cards to move, archive or restore them, with a per-card result.
- Show My tasks grouped by due date and as a month calendar.
- Add quick due dates (today, tomorrow, next week, none) to the card editor.
- Add checklist items in bulk and hide completed ones; continue lists on Enter with a formatting bar.
- Mention people in comments, show card activity and linked projects, copy comment text.
- Share text and links from other apps into a new card, on Android and iOS.
- Share a card as text and a board link through the system share sheet.
- Send queued changes in the background and remind about due dates (both optional).
- Show the last sync time with a Sync now button, and copyable technical details on sync errors.
- Remember board filters and the last opened board per account.
- Fix lost edits when a change was merged while sending, interrupted comments, and migration failures.
- Keep app passwords out of iOS backups.

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
