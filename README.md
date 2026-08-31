# continuity

Menu bar commands to kick Continuity Camera and Mic back to life, plus a live read on
which iPhone macOS currently sees.

When your iPhone stops showing up as a camera or mic, the fix is almost always restarting
one of the launchd agents behind it. This is a tray icon that does that, so you don't have
to open a terminal mid-call.

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

Every target is a launchd on-demand job, so killing it is a restart. The two root items use
the standard macOS authorisation prompt.

## Feedback

Each command reports three ways, so you see the result whether or not the menu is open:

- **Notification** — title/subtitle/result, posted through `osascript`, because an unbundled
  SwiftPM binary has no bundle identifier and `UNUserNotificationCenter` needs one.
- **Menu history** — a `Recent` section with the last 8 results and their timestamps.
- **Log** — `~/Library/Logs/continuity.log`, opened with the `Open log` menu item.

## Run

```bash
just run          # swift run Continuity
just check        # fmt + loc + dir + lint + build + test
```

The app is an accessory app — menu bar only, no dock icon, no window.

## Layout

```
continuity/
  App.swift       # @main + MenuBarExtra menu
  Runner.swift    # runs an action, reports the result three ways
  Actions.swift   # the command list
  Status.swift    # which phone macOS currently exposes
  Shell.swift     # process runner (+ admin via NSAppleScript)
  Feedback.swift  # log file + notification
Tests/ContinuityTests/ShellTests.swift
```
