First release.

A menu bar app for when your iPhone stops showing up as a camera or microphone. It
restarts the launchd agents behind Continuity, and shows you what macOS currently sees.

- **Status** — the paired phone, its model, and whether the camera and mic are ready,
  in use, suspended, or disconnected. Refreshes on device connect/disconnect.
- **Commands** — reconnect the capture agent, restart AV conferencing, restart device
  discovery, kick all of them at once, restart the audio stack, bounce Bluetooth,
  bounce Wi-Fi. The last three ask for an administrator password.
- **Feedback** — every result appears as a notification, in a `Recent` section in the
  menu, and in `~/Library/Logs/continuity.log` (`Open log` opens it in Console).
- Signed, notarized, and updates itself through Sparkle.
