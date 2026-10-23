# OwnDeck

![Version](https://img.shields.io/badge/version-0.1.0--dev-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.44.4-blue)
![Platforms](https://img.shields.io/badge/platforms-Android%20%7C%20iOS-green)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

OwnDeck is a Flutter client for Nextcloud Deck on Android and iOS, currently under development.

## Features

- 📋 **Planning** - Product requirements, API findings, and implementation tasks are tracked in this repository.
- 🔌 **API reference** - An inventory covers 86 versioned routes from Deck 1.19.1.
- 📱 **Mobile client** - Initial code supports Nextcloud browser sign-in, secure account storage, and board browsing under `com.nkshub.nextclouddeck`.

Board editing, offline synchronization, and telemetry are implementation work in progress. See [TODO.md](TODO.md) for their status.

## Requirements

- Flutter 3.44.4 with Dart 3.12.2.
- Android SDK for Android builds; macOS and Xcode for iOS builds.
- A Nextcloud server with Deck enabled for integration tests.
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

The commands above start the development client; device acceptance has not been completed.

## Configuration

The application version is recorded in `VERSION`. Sentry and Rybbit will be optional build configuration, supplied through CI for publisher builds. Builds without that configuration must operate without either service.

Credentials, signing files, local environments, and runtime logs must stay outside Git. Runtime ingestion configuration is readable from an application binary; administrative service tokens must never be bundled.

The [product specification](docs/product.md), [API analysis](docs/nextcloud-api.md), and [architecture](docs/architecture.md) are written in Czech.

## Development

Use [TODO.md](TODO.md) to select the next task. Application tests and physical-device acceptance are planned in [docs/testing.md](docs/testing.md); no application test results are claimed yet.

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
