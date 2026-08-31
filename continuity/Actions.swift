import Foundation

/// One menu command: a shell line, optionally run as root via the macOS auth dialog.
struct Action: Identifiable {
    var id: String { title }
    let title: String
    let command: String
    var admin = false
}

extension Action {
    /// Verified against the daemons macOS 26 actually runs — `ContinuityCaptureAgent` is the
    /// one serving iPhone camera/mic; the rest are the discovery and transport layers under it.
    /// All of them are launchd on-demand jobs, so killing them is a restart, not a shutdown.
    static let all: [Action] = [
        Action(title: "Reconnect iPhone", command: "killall ContinuityCaptureAgent"),
        Action(title: "Restart AV conferencing", command: "killall avconferenced"),
        Action(title: "Restart device discovery", command: "killall sharingd rapportd"),
        Action(
            title: "Full kick",
            command: "killall ContinuityCaptureAgent avconferenced sharingd rapportd"
        ),
        Action(title: "Restart audio stack…", command: "killall coreaudiod", admin: true),
        Action(title: "Bounce Bluetooth…", command: "killall bluetoothd", admin: true),
        Action(title: "Bounce Wi-Fi", command: wifiBounce)
    ]

    private static let wifiBounce = """
        dev=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')
        networksetup -setairportpower "$dev" off
        sleep 2
        networksetup -setairportpower "$dev" on
        """
}
