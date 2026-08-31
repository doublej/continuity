# continuity

Menu bar commands to kick Continuity Camera and Mic back to life, plus a live read on
which iPhone macOS currently sees.

When your iPhone stops showing up as a camera or mic, the fix is almost always restarting
one of the launchd agents behind it. This is a tray icon that does that, so you don't have
to open a terminal mid-call.

## Install

Download the zip from [Releases](https://github.com/doublej/continuity/releases), unzip,
and drag `continuity.app` to `/Applications`. It is signed and notarized, so it opens
without a Gatekeeper detour, and it updates itself from then on (Sparkle, daily check —
`Check for Updates…` in the menu forces one).

## Status

The top of the menu shows the paired phone as macOS sees it, and the menu bar icon flips
between `iphone.badge.play` and `iphone.slash` depending on whether one is there:

```
Pocketline Swing — iPhone18,1
Camera: ready · Mic: ready
```

Camera and mic arrive as two separate `AVCaptureDevice`s sharing a `uniqueID` prefix; the
app pairs them back into one phone. Per device it reports `ready`, `in use` (another app
has it), `suspended`, or `disconnected`. It refreshes on device connect/disconnect
notifications, after every command, and on `Refresh`.

Worth knowing: a Continuity camera reports as `.external`, **not** `.continuityCamera`, so
the model ID (`iPhone…`, `iPad…`) is what actually identifies it.

## Commands

| Menu item | What it does | Root |
|---|---|---|
| Reconnect iPhone | `killall ContinuityCaptureAgent` — the agent that actually serves the iPhone camera/mic | |
| Restart AV conferencing | `killall avconferenced` | |
| Restart device discovery | `killall sharingd rapportd` — proximity + Handoff discovery | |
| Full kick | all four of the above at once | |
| Restart audio stack… | `killall coreaudiod` — for a dead Continuity mic | yes |
| Bounce Bluetooth… | `killall bluetoothd` — Continuity needs BT up | yes |
| Bounce Wi-Fi | power cycles the Wi-Fi port | |

Every target is a launchd on-demand job, so killing it is a restart. The three root items
ask for an administrator password through the standard macOS prompt.

## Feedback

Each command reports three ways, so you see the result whether or not the menu is open:

- **Notification** — title, command, result.
- **Menu history** — a `Recent` section with the last 8 results and their timestamps.
- **Log** — `~/Library/Logs/continuity.log`; `Open log` opens it in Console.

## Build

```bash
just install      # xcodegen + swiftlint check
just run          # signed debug build, launched
just check        # fmt + loc + dir + lint + build + test
```

Needs XcodeGen and SwiftLint (`brew install xcodegen swiftlint`) and the Developer ID
certificate in the login keychain — signing is manual and never falls back to ad-hoc.

## Release

```bash
just next            # what the next version would be
just bump [part]     # gate, then version commit + annotated tag
just publish         # notarize, GitHub release, then rewrite and push the appcast
```

The version lives only in `project.yml`. `appcast.xml` at the repo root is the Sparkle
feed, served raw from `main` — it is the last thing `just publish` pushes, so it never
names a download that is not on the release yet.

## Layout

```
continuity/
  App.swift       # @main + MenuBarExtra menu
  Runner.swift    # runs an action, reports the result three ways
  Actions.swift   # the command list
  System/
    Shell.swift     # subprocess runner, plain and as root
    Status.swift    # which phone macOS currently exposes
    Feedback.swift  # log file + notification
    Updater.swift   # Sparkle
Tests/ContinuityTests/
project.yml       # XcodeGen input: targets, signing, version
```
