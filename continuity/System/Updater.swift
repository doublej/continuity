import Foundation
import Sparkle

/// Sparkle, kept behind one door so nothing else in the app imports it.
///
/// The controller is built lazily and only when a feed exists: Sparkle aborts with a
/// fatal error when it starts without `SUFeedURL`, so a build whose feed was stripped
/// hides the menu item instead of offering a button that crashes.
@MainActor
enum Updater {
    static let isConfigured =
        !((Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String) ?? "").isEmpty

    /// Bringing the controller into existence is what schedules the daily check —
    /// without this call nothing checks until somebody presses the menu item.
    static func start() {
        guard isConfigured else { return }
        _ = controller
    }

    static func checkForUpdates() {
        guard isConfigured else { return }
        controller.checkForUpdates(nil)
    }

    private static let controller = SPUStandardUpdaterController(
        startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
}
