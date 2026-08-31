# continuity

Menu bar commands to kick Continuity Camera and Mic back to life.

When your iPhone stops showing up as a camera or mic, the fix is almost always
restarting one of the launchd agents behind it. This is a tray icon that does that,
so you don't have to open a terminal mid-call.

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
| List cameras | shows what macOS currently sees, to confirm the iPhone came back | |

Every target is a launchd on-demand job, so killing it is a restart. The two root items
use the standard macOS authorisation prompt. Output (or `✓`) lands in the menu itself.

## Run

```bash
just run          # swift run Continuity
just check        # fmt + loc + dir + lint + build + test
```

The app is an accessory app — menu bar only, no dock icon, no window.

## Layout

```
continuity/
  App.swift       # @main + MenuBarExtra + Runner
  Actions.swift   # the command list
  Shell.swift     # process runner (+ admin via NSAppleScript)
Tests/ContinuityTests/ShellTests.swift
```
