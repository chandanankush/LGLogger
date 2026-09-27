# LGLogger

[![CI](https://github.com/chandanankush/LGLogger/actions/workflows/ci.yml/badge.svg)](https://github.com/chandanankush/LGLogger/actions/workflows/ci.yml)
[![CodeQL](https://github.com/chandanankush/LGLogger/actions/workflows/codeql.yml/badge.svg)](https://github.com/chandanankush/LGLogger/actions/workflows/codeql.yml)
![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.10-orange)

LGLogger helps iOS developers inspect their app's own diagnostic messages with `print()`-style calls, module and severity filters, optional saved logs, and a floating in-app log viewer. It is a small Swift package with no package dependencies, for **iOS 17+ and Swift 5.10+**.

[Install](#install) · [Runnable example](#try-it-in-a-demo-app) · [API reference](docs/REFERENCE.md) · [Questions and feedback](https://github.com/chandanankush/LGLogger/discussions) · [Contribute](CONTRIBUTING.md)

## Install

In Xcode, choose **File → Add Package Dependencies…**, enter:

```text
https://github.com/chandanankush/LGLogger.git
```

Choose **Up to Next Major Version from 1.0.0**, add the `LGLogger` product to your iOS app target, then `import LGLogger`. [Tag 1.0.0](https://github.com/chandanankush/LGLogger/tree/1.0.0) exists; there is no packaged GitHub Release. The README on `main` describes current source; choose a branch deliberately if testing changes after that tag.

For another Swift package, add the dependency and target product to your existing manifest:

```swift
// In Package(...):
dependencies: [
    .package(url: "https://github.com/chandanankush/LGLogger.git", from: "1.0.0")
],
targets: [
    .target(name: "YourTarget", dependencies: [
        .product(name: "LGLogger", package: "LGLogger")
    ])
]
```

For local development, clone this repository and use Xcode's **Add Local…** package option; any folder location works. Build using an iOS destination: macOS `swift build` / `swift test` cannot compile its UIKit and MessageUI imports.

## Try it in a demo app

Create a disposable SwiftUI **iOS 17+** app, add the package, and replace its generated app entry point with this example. It writes only invented messages in the demo app's sandbox; it has no upload endpoint.

```swift
import SwiftUI
import LGLogger

@main
@MainActor
struct LoggingDemoApp: App {
    var body: some Scene {
        WindowGroup {
            Button("Write a demo message") {
                LGPrint("Demo", "Button tapped", level: .info)
            }
            .onAppear {
                #if DEBUG
                LGSettings.enableFileLogging(levels: [.info, .warning, .error])
                LGOverlay.install()
                #endif
            }
        }
    }
}
```

Run a Debug build on an iOS simulator, press the button, then tap the floating bubble to open the saved log. File logging starts **off**; the example opts in for Debug builds. The overlay is optional and can be installed once from your own UI lifecycle.

## Everyday usage

```swift
LGPrint("hello")                                  // .debug by default
LGPrint("Auth", "Example session expired", level: .warning)
LGSettings.setLogLevel(onlyModules: ["Auth"])       // exact module matches
LGSettings.showConsole(onlyLevels: [.warning, .error])
LGSettings.enableFileLogging(levels: [.error])      // independent file severity filter
LGSettings.setLogLevelAll()                        // remove module filter
LGSettings.disableFileLogging()
```

An active module filter also suppresses untagged calls. `.debug` messages are suppressed in non-DEBUG builds regardless of filters; use an explicit `.info` or higher level for release diagnostics. The message expression is evaluated only when an enabled destination consumes it. See the [reference](docs/REFERENCE.md) for output methods, file locations, upload APIs, overlay behavior, and architecture.

## Privacy and limitations

- Only explicit `LGPrint` messages are saved; this does not capture all process stdout/stderr. Avoid logging tokens, passwords, personal data, or private payloads. File logging has no built-in size limit or retention policy.
- Email and HTTP actions process **all saved log files**. Successful sends/uploads delete those files. A partly failed HTTP batch can already have deleted successful files; failures do not roll them back. Review logs before sharing them.
- HTTP upload is one plain-text POST per file, with no authentication-header API, multipart support, or retry. Mail attachments are loaded into memory. No endpoint is configured by default; Upload appears only after you supply `LGSettings.uploadURL`.
- A file-open failure disables further file writes for that process launch. Relaunching is needed to try again.
- The overlay's position is not saved across launches, and its drag bounds are not recalculated on rotation or iPad window resize. Device compatibility feedback is welcome.
- The package currently has one iOS-only target. The existing simulator tests cover routing, file-sink behavior, clamping, and helpers; network POST/delete behavior and full UI interactions are not covered by those unit tests.

## Support and contribution

Use [Discussions](https://github.com/chandanankush/LGLogger/discussions) for integration questions and feedback. Report reproducible problems in [Issues](https://github.com/chandanankush/LGLogger/issues) with your iOS version, Xcode version, package tag/commit, and a minimal demo using invented data. Start with [CONTRIBUTING](CONTRIBUTING.md) for safe simulator validation and scoped tasks.

This repository currently contains **no license file**. Public source availability alone does not grant reuse or redistribution rights; ask the maintainer about licensing before adopting it in a distributed app.
