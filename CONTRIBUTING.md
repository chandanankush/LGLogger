# Contributing to LGLogger

Start with [Discussions](https://github.com/chandanankush/LGLogger/discussions) for integration questions or a proposed change. Use [Issues](https://github.com/chandanankush/LGLogger/issues) for reproducible problems. Check existing issues first; `good first issue` identifies a small scoped task, while `help wanted` includes broader device verification. No license file is currently supplied; clarify contribution and reuse terms with the maintainer before submitting code.

## Read the code

Public call sites are in `Sources/LGLogger/LGPrint.swift`; settings routing is in `LGSettings.swift`. The [API and implementation reference](docs/REFERENCE.md) preserves file responsibilities, overlay coordinate-system cautions, and design notes. Tests live in `Tests/LGLoggerTests/`.

## Safe validation

Use Xcode with an installed iOS 17+ simulator. List available destinations and choose one you have:

```sh
xcrun simctl list devices available
xcodebuild test -scheme LGLogger \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Replace the simulator name as needed. The package imports UIKit and MessageUI, so `swift test` targeting macOS is not a valid check. Existing tests use doubles for file operations; the empty-log uploader test does not send a request. Do not replace them with tests against a production endpoint or a real app's saved logs.

For manual UI testing, use a disposable host app and invented messages, with no upload URL and no personal data. Never email or upload logs without inspecting them and obtaining destination authorization. Uploads can delete successfully sent files. Record device, iOS, Xcode, tag/commit, and exact steps; avoid general compatibility claims based on one simulator.

## Submitting a change

Keep the change focused, describe the problem and expected behavior, and run relevant existing simulator tests. Preserve global settings between tests. Do not introduce dependencies, platform claims, or behavioral changes in a documentation-only contribution. Include sanitized output only.
