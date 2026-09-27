# LGLogger API and implementation reference

User setup and a runnable app example are in the [README](../README.md).

## Contents

| File | What it is |
|---|---|
| `LGPrint.swift` | The two `LGPrint(...)` call-site functions, and the internal `LGLog.emit` that does the work. |
| `LGLevel.swift` | `LGLevel`: `.debug` / `.info` / `.warning` / `.error`, each with an emoji prefix. |
| `LGSettings.swift` | All runtime configuration: module filter, per-destination level filters, output method, file-logging on/off. |
| `LGFileSink.swift` | Writes `LGPrint` lines to a per-launch log file. Lists/deletes saved log files. |
| `LGFileManagerProtocol.swift` / `LGFileHandleFactory.swift` | Thin protocol/class seams around `FileManager`/`FileHandle` so `LGFileSink` is unit-testable. |
| `LGUtility.swift` | `Date.toISO8601String()`, used to name each launch's log file/folder. |
| `LGUploadError.swift` | Shared `Error` type for both uploaders. |
| `LGMailUploader.swift` | Presents the system mail composer with every saved log file attached. |
| `LGNetworkUploader.swift` | POSTs every saved log file to a URL you provide. |
| `LGOverlay.swift` | Public entry point: `LGOverlay.install()` attaches the floating bubble to every scene. |
| `LGOverlayWindow.swift` | The extra, always-on-top `UIWindow` the bubble lives in; implements touch pass-through. |
| `LGOverlayState.swift` | Shared `ObservableObject` for the bubble's position, drag-clamping, and viewer-presented flag. |
| `LGBubbleView.swift` | The draggable bubble itself (SwiftUI). |
| `LGLogViewerView.swift` | The list-and-read-a-log-file screen the bubble opens, with Email/Upload/Clear actions. |

All types are `internal` (package-private) except the ones a consuming app actually needs
to call: `LGPrint`, `LGLevel`, `LGSettings`, `LGOverlay`, `LGMailUploader`,
`LGNetworkUploader`, and `LGUploadError`. If you add a new file here that the host app
needs to call directly, remember to mark it `public` — the module boundary is real now
(unlike before this was a package, when everything shared one app-target module).

## Quick start

```swift
import LGLogger

// Once, at launch (e.g. your App's init()):
LGSettings.enableFileLogging()   // off by default — turn on to persist to disk
LGOverlay.install()               // adds the floating "view logs" bubble to every scene

// Anywhere in the app:
LGPrint("hello")                              // level defaults to .debug
LGPrint("Auth", "user logged in")             // tagged with a module name
LGPrint("Auth", "token expired", level: .error)
```

`LGPrint`'s `message` argument is `@autoclosure` — if neither console nor file logging
would actually consume a given call, the message expression is never evaluated, so
expensive `String(describing:)`-style calls cost nothing when logging for them is off.

## Filtering (`LGSettings`)

Two independent axes, both defaulting to "everything visible, nothing saved":

- **Module filter — shared by console *and* file, one knob:**
  ```swift
  LGSettings.setLogLevel(onlyModules: ["Auth"])   // only "Auth"-tagged lines print AND save
  LGSettings.setLogLevelAll()                      // reset: every module, both destinations
  ```
  A log call with no module tag (`LGPrint("hi")`, no module argument) is treated as *not
  matching* any active module filter, so it goes quiet on both destinations while a
  filter is set.

- **Severity filter — independent per destination:**
  ```swift
  LGSettings.showConsole(onlyLevels: [.warning, .error])   // console only
  LGSettings.showAllLevelsInConsole()                       // reset

  LGSettings.enableFileLogging(levels: [.error])            // file only, and turns saving on
  LGSettings.enableFileLogging()                            // saving on, every level
  LGSettings.disableFileLogging()                           // back to the default (off)
  ```
  `enableFileLogging(levels:)` is the single call that both turns file-saving on *and*
  sets its level filter — there is no separate "just change the level" call while
  keeping it enabled; call it again with the new level list.

- **Output method** (console only — doesn't affect the file):
  ```swift
  LGSettings.outputMethod = .nslog   // default is .print
  ```

`.debug`-level calls are compiled out of non-DEBUG builds entirely (`#if !DEBUG` in
`LGLog.emit`), regardless of any of the above settings.

All state in `LGSettings` is guarded by a single `NSLock`; `destinations(forModule:level:)`
takes that lock exactly once per `LGPrint` call and returns everything the call site needs
in one shot, rather than re-acquiring the lock per flag.

## Where logs are saved (`LGFileSink`)

- Location: `<Application Support>/<bundle identifier>/LGPrint/<launch-ISO8601-timestamp>/<same-timestamp>.log`
- A **new file per process launch** (named after the process's actual start time, via
  `sysctl(KERN_PROC)`, not `Date()` — falls back to `Date()` only if that syscall fails).
  There is no cross-launch appending; every run of the app gets its own file.
  Restarting the app produces a *new* file, not a continuation of the old one.
- The file is opened lazily, on the first line actually written (i.e. the first call
  that passes both the module and level filter while file logging is enabled) — turning
  on file logging with nothing subsequently logged never touches disk.
  Each line is just `<emoji> [<module>] <message>` (the `[<module>] ` part is omitted
  when a call has no module) — there's no per-file header line.
- If opening the file fails (bad permissions, disk full, etc.), that failure is
  remembered (`didFailToOpen`) so every subsequent `append` call is a cheap early-return
  instead of retrying the file-system work on every single log line — but this also
  means a transient failure is permanent for the rest of that launch; there's no retry.
- `LGFileSink` is completely independent of `LGPrint`'s console path: enabling `.nslog`
  as the output method has no effect on what gets saved, and vice versa.

## Uploading (`LGMailUploader`, `LGNetworkUploader`)

The normal way to trigger these is the **"Email Logs" / "Upload Logs" buttons already
built into `LGLogViewerView`** (see [Floating debug overlay](#floating-debug-overlay-lgoverlay)
below) — you don't need to call these APIs directly unless you're building your own UI
around them. Both operate on **every file** `LGFileSink.shared.allLogFileURLs()` currently
returns — i.e. every launch's log file that hasn't been deleted yet, not just the current one.

```swift
// Mail — must run on the main actor, needs a presenting UIViewController.
LGMailUploader.present(from: someViewController) { result in
    // .success: user tapped Send, files were deleted.
    // .failure(.mailCancelled): cancelled or saved as draft — files are left alone.
    // .failure(.mailUnavailable): device has no Mail account configured.
}

// Network — plain POST per file, no auth/multipart support.
LGNetworkUploader.upload(to: someURL) { result in
    // .success: every file uploaded and was deleted.
    // .failure: at least one file failed; failed files are NOT deleted, succeeded ones already were.
}
```

Notes:
- `LGNetworkUploader` uploads files **concurrently** and deletes each one as soon as its
  own upload succeeds — a failure on one file doesn't block or roll back the others. The
  completion handler reports only the *first* failure encountered; if you need to know
  about every failed file individually, this isn't currently exposed.
- The network request is a bare `POST` with `Content-Type: text/plain` and an
  `X-Log-File-Name` header — no multipart form encoding, no auth headers, no retry. If
  your backend expects `multipart/form-data` or needs an `Authorization` header, you'll
  need to extend `uploadFile(at:to:session:completion:)`.
- Mail attachments are read fully into memory (`Data(contentsOf:)`) before attaching —
  fine for typical text logs, could be a problem for very large accumulated log sets.

## Floating debug overlay (`LGOverlay`)

```swift
LGOverlay.install()   // call once; safe to call multiple times (no-ops after the first)
```

- Adds a second, transparent `UIWindow` (`LGOverlayWindow`) into *every* `UIWindowScene`
  as it becomes key (via `UIWindow.didBecomeKeyNotification`), at `windowLevel = .alert + 1`
  — including scenes that connect after `install()` was called (e.g. new document
  windows in a host app). Cleans up its entry on `UIScene.didDisconnectNotification`.
- The bubble is draggable anywhere on screen and is clamped to stay clear of the safe
  area (status bar / Dynamic Island / home indicator) on all four edges — see
  [Limitations](#limitations) for why that clamp exists.
- Tapping (not dragging) it opens `LGLogViewerView`, a list of every saved log file →
  tap one to read its raw contents.
- The list screen's `⋯` menu has **Email Logs**, **Upload Logs**, and **Clear Logs**
  (destructive, behind a confirmation dialog). The whole menu only appears once there's
  at least one saved log file; **Upload Logs** specifically is further hidden unless
  `LGSettings.uploadURL` has been set (`nil` by default) — the package doesn't hardcode
  an endpoint, so hosts that never opt in never see a button pointing nowhere.
  Presenting the mail composer from here uses a small `UIViewControllerRepresentable`
  helper (`LGViewControllerResolver`) to find the *actual* presenting view controller —
  since this view can be hosted inside `LGOverlayWindow` rather than the app's own main
  window, looking up "the key window's root VC" the naive way would find the wrong
  window and the composer could render behind the overlay.
- Touch pass-through: `LGOverlayWindow.hitTest` only claims touches within ~40pt of the
  bubble's center (or, while the log viewer is presented, everywhere) — every other touch
  returns `nil`, falling through to the app's own window underneath, so the overlay never
  blocks normal use of the app.

### The safe-area bug (read this before touching bubble positioning code)

The bubble's position (`LGOverlayState.bubbleCenter`) and `LGOverlayWindow.hitTest`'s
touch-distance check are both expressed in **raw, full-window coordinates** — the same
space as `scene.coordinateSpace.bounds`. SwiftUI's `.position(x:y:)` modifier, however,
lays out relative to the *safe-area-adjusted* canvas by default. Mixing the two silently
offsets the rendered bubble from where hit-testing expects it — on the test device this
was consistently ~60–67pt in just the vertical axis (matching the top safe-area inset),
which made the bubble render, but made every tap/drag miss it entirely with zero visible
symptom other than "nothing happens."

The fix in `LGBubbleView` is to *not* use `.position()` at all: it wraps the bubble in a
`ZStack(alignment: .topLeading)` inside a `.frame(maxWidth: .infinity, maxHeight: .infinity)`
container marked `.ignoresSafeArea()`, then places the bubble with `.offset(x:y:)` from
that container's top-left corner — which is the window's true `(0, 0)`, matching every
other coordinate this module uses. **If you ever reintroduce `.position()` here (or add
another overlay window elsewhere in this module), re-verify this alignment** — the
symptom of getting it wrong is total, silent unresponsiveness, not a visible offset.

Separately, `LGOverlayState.clamp(_:)` keeps the bubble's center at least `bubbleRadius`
away from each safe-area inset (not just the screen edge). Without this, dragging the
bubble fully into the status-bar/Dynamic-Island strip or the home-indicator strip could
make it ungrabbable again — those regions can be reserved for system gesture handling
regardless of this window's `windowLevel`.

### Debugging this again in the future

If touches ever stop reaching the bubble again, the fastest way back to a root cause is
to temporarily re-add point-by-point logging in `LGOverlayWindow.hitTest` and in the
`DragGesture`'s `onChanged`/`onEnded` closures, comparing the raw `point`/`location`
values against `state.bubbleCenter`. **Use `NSLog`, not `print`, for anything you need to
see quickly** — `print()`'s stdout is block-buffered when not attached to a TTY, so
output was observed to not appear at all over several seconds of interaction (until the
process was killed and its buffer flushed); `NSLog` goes through the unified logging
system and shows up immediately, both in Xcode's console and via `log show`/`log stream`.

## Architecture notes

- **Thread-safety**: `LGSettings` and `LGFileSink` protect their mutable state with a
  plain `NSLock` (`nonisolated(unsafe)` stored properties + `lock.withLock { }`), rather
  than relying on any host project's actor-isolation defaults — this module is meant to
  be dropped into other projects, and their Swift concurrency settings shouldn't change
  whether this logger is safe to call from a background thread.
- **`@MainActor` is used explicitly** wherever UIKit/SwiftUI is unavoidably involved
  (`LGOverlay`, `LGOverlayState`, `LGMailUploader`) — again, not relying on a host
  project's `SWIFT_DEFAULT_ACTOR_ISOLATION` setting.
- **DI seams for testability**: `LGFileSink` depends on `LGFileManagerProtocol` and
  `LGFileHandleFactory` (both `var`, package-internal) instead of talking to
  `FileManager`/`FileHandle` directly, so file I/O can be faked in the existing `LGFileSinkTests`.
- **Two independent file-writing mechanisms existed at one point** during this module's
  development: an earlier `LGRecorder` captured the *entire process's* `stdout`/`stderr`
  via `dup2`, while `LGFileSink` writes only `LGPrint` lines explicitly. `LGRecorder` was
  removed once `LGFileSink` covered the primary use case — if you see references to it
  in old notes/history, it no longer exists.
- **This used to be plain files compiled into the app target**, not a package — access
  levels (`public` vs. internal) were assigned with an eventual package split already in
  mind, which is why the SPM conversion needed zero access-level changes: anything the
  app called from outside the `logger/` folder was already `public`.

## Limitations

- **iOS/UIKit only.** `LGOverlay*`, `LGBubbleView`, `LGLogViewerView`, and
  `LGMailUploader` all assume `UIWindowScene`/`UIViewController`. `LGPrint`,
  `LGSettings`, `LGFileSink`, and `LGNetworkUploader` have no UIKit dependency and could
  work on other Apple platforms, but the package currently declares a single iOS-only
  target rather than splitting a platform-agnostic core out.
- **`swift build` alone won't build this package** — it targets macOS by default, and
  `MessageUI` doesn't exist there. Build/validate it via Xcode (`xcodebuild -scheme
  LGLogger -destination 'platform=iOS Simulator,...'`) or as part of the app target.
- **File-open failures are permanent per launch.** If `LGFileSink` fails to open its log
  file once (e.g. transient disk-full), it won't retry for the rest of that process's
  life — you'd need to relaunch the app to try again.
- **Network uploader is intentionally minimal.** Plain `POST`, no multipart, no auth
  headers, no retry, and only the *first* per-batch failure is reported back — see
  [Uploading](#uploading-lgmailuploader-lgnetworkuploader).
- **`allLogFileURLs()` returns every launch's file, unfiltered.** There's no built-in way
  to upload/email only "logs from the last N launches" or apply a date range — callers
  get everything currently on disk.
- **The floating bubble has no persisted position across launches** — it always starts
  at the same default corner each time `LGOverlay.install()` runs; dragging it only
  persists for the current process lifetime.
- **`LGOverlay` doesn't handle interface rotation.** `bounds`/`safeAreaInsets` are
  captured once, when a scene's window first becomes key, and never recalculated — an
  in-place rotation or Split View resize on iPad wouldn't update the bubble's drag
  bounds. It would take a fresh `didBecomeKeyNotification` (e.g. backgrounding and
  returning) for these to catch up, if they even do at that point.

## Testing

Unit tests live in `Tests/LGLoggerTests/` and cover the logic-bearing, side-effect-light
parts of the package:

| Test file | What it exercises |
|---|---|
| `LGSettingsTests.swift` | The `destinations(forModule:level:)` routing matrix — module filter, per-destination level filters, output method, upload URL. |
| `LGFileSinkTests.swift` | Lazy file open, newline-terminated appends, and the "give up permanently on open failure" behaviour, via the `LGFileManagerProtocol` seam. |
| `LGOverlayStateTests.swift` | Bubble-position clamping against scene bounds and safe-area insets. |
| `LGLevelTests.swift` / `LGUploadErrorTests.swift` / `DateISO8601Tests.swift` | Level bitmask/prefix mapping, error descriptions, log-file timestamp format. |
| `LGNetworkUploaderTests.swift` | The empty-set guard on the public upload entry point. |

Because the package imports `UIKit`/`SwiftUI`/`MessageUI`, it builds only for an Apple UI
platform — **`swift test` won't work; run the suite through an iOS simulator**:

```sh
xcodebuild test \
  -scheme LGLogger \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

(Any available iPhone simulator works — pick one from `xcrun simctl list devices available`.)

## Continuous integration & code scanning

`.github/` wires up GitHub-native checks for the public repo:

- **`workflows/ci.yml`** — builds and runs the test suite on a `macos-latest` runner
  against a simulator it picks dynamically (runner image device names change over time),
  on every push and PR to `main`.
- **`workflows/codeql.yml`** — GitHub **code scanning** via CodeQL for Swift (`build-mode:
  manual`, building for the simulator), on push/PR plus a weekly scheduled re-scan.
  Findings surface under the repo's **Security → Code scanning** tab.
- **`dependabot.yml`** — weekly update PRs for the GitHub Actions used above (the package
  itself has no SPM dependencies to track).

## Suggested next steps

- Extend `LGNetworkUploader` coverage: it currently reads from the `LGFileSink.shared`
  singleton, so the POST/delete path can't be unit-tested in isolation — decoupling it
  from the singleton (inject the file list) would let a `URLProtocol` stub cover success,
  partial-failure, and delete-on-success behaviour.
- Split a platform-agnostic core target (`LGPrint`/`LGSettings`/`LGFileSink`/
  `LGNetworkUploader`) out from the iOS-only UI pieces, if non-Apple-UIKit platform
  support is ever needed.
- Decide whether `LGSettings`'s module filter should support case-insensitive or
  wildcard/prefix matching (currently exact `Set<String>` membership).
- Consider exposing per-file failure detail from `LGNetworkUploader` instead of just the
  first error, if a caller needs to know exactly which files didn't make it.
- Consider persisting the bubble's dragged position (e.g. `UserDefaults`) across launches.
