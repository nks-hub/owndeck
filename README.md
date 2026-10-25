# OwnDeck

[![CI](https://github.com/nks-hub/owndeck/actions/workflows/ci.yml/badge.svg)](https://github.com/nks-hub/owndeck/actions/workflows/ci.yml)
![Version](https://img.shields.io/badge/version-0.1.0--dev-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.44.4-blue)
![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS-green)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

OwnDeck is a Flutter client for Nextcloud Deck on Android and iOS, currently under development.

## Features

- 📋 **Boards and cards** - Board and column management, labels, assignments, due dates, card copies, related cards and done columns.
- 💾 **Offline work** - Cached data, saved card and comment drafts, a persistent write queue and explicit conflict decisions.
- 📎 **Files and comments** - Upload, download, export and link Nextcloud files; read, write and edit comments.
- 🔎 **Search** - Local and server search, task filters, and links that open the correct account and card.
- 🔐 **Accounts** - Browser and QR sign-in, separate account data and system credential storage.
- 📊 **Optional diagnostics** - CI-configured Dart/Flutter error reporting and usage events, with separate opt-out switches.

The client uses `com.nkshub.nextclouddeck`. See [TODO.md](TODO.md) and [verification results](docs/testing.md) for the current scope and acceptance limits.

## Requirements

- Flutter 3.44.4 with Dart 3.12.2.
- Android 7 or later (API 24), with Android SDK for builds.
- macOS and Xcode 26.3 for iOS builds.
- iOS 14 or later, required by the system file picker.
- A Nextcloud server with Deck API 1.1. Live compatibility is verified with Deck 1.18.5; its API already supports card start dates and colors from the 1.18 release family.
- OpenSSL for local TLS tests.
- Python 3.10+ to regenerate the API inventory.

## Installation

```sh
git clone https://github.com/nks-hub/owndeck.git
cd owndeck
cd apps/mobile
flutter pub get
flutter run
```

Repository access is currently restricted while development is in progress.

These commands start a development build. Distribution signing and store publishing are separate steps.

## Configuration

The application version is recorded in `VERSION`. Ordinary builds do not initialize Sentry or Rybbit. Publisher CI requires the repository secrets `SENTRY_DSN`, `RYBBIT_HOST` and `RYBBIT_SITE_ID`, and generates an ignored `telemetry.json` file for the build. Each service can be disabled in the app. Native crash, hang, replay and automatic session collection are disabled.

Credentials, signing files, local environments, and runtime logs must stay outside Git. Runtime ingestion configuration is readable from an application binary; administrative service tokens must never be bundled.

The [product specification](docs/product.md), [API analysis](docs/nextcloud-api.md), and [architecture](docs/architecture.md) are written in Czech.

## Development

Use [TODO.md](TODO.md) to select the next task. Tests run in isolated checkouts during development; [docs/testing.md](docs/testing.md) records the tested revisions and distinguishes API, device and build evidence. Run `dart test` in each package and `flutter test` in `apps/mobile`.

To regenerate the source-based API inventory:

```sh
python tool/inventory_deck_api.py
```

## Contributing

1. Fork the repository when access is available.
2. Create a branch for one change.
3. Commit the change with a message such as `feat: add board filtering`.
4. Push your branch.
5. Open a pull request with the behavior and verification results.

## Support

- 📧 **Email:** dev@nks-hub.cz
- 🐛 **Bug reports:** [GitHub Issues](https://github.com/nks-hub/owndeck/issues)

## License

MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">Made with ❤️ by <a href="https://github.com/nks-hub">NKS Hub</a></p>
