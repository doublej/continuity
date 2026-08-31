import Foundation
import Testing
@testable import Continuity

@Test func shellReturnsStdout() async {
    #expect(await Shell.run("echo hi") == "hi\n")
}

@Test func shellFoldsStderrIntoOutput() async {
    #expect(await Shell.run("echo oops >&2").contains("oops"))
}

@Test func everyActionHasAUniqueIdAndRunnableCommand() async {
    #expect(Set(Action.all.map(\.id)).count == Action.all.count)
    for action in Action.all {
        #expect(await Shell.run("zsh -n -c \(shellQuote(action.command))").isEmpty)
    }
}

private func shellQuote(_ text: String) -> String {
    "'" + text.replacingOccurrences(of: "'", with: "'\\''") + "'"
}

@Test func quotingSurvivesAShellRoundTrip() async {
    let nasty = #"it's "quoted" \ $(whoami) `id` ;rm"#
    #expect(await Shell.run("printf %s \(Shell.quote(nasty))") == nasty)
}

@Test func appleScriptLiteralSurvivesAnOsascriptRoundTrip() async {
    let nasty = #"back\slash and "quotes""#
    let source = "return \(Feedback.literal(nasty))"
    #expect(await Shell.run("osascript -e \(Shell.quote(source))") == nasty + "\n")
}

@Test func phoneNameDropsTheRoleWord() {
    #expect(Status.baseName("Pocketline Swing Camera") == "Pocketline Swing")
    #expect(Status.baseName("Solo") == "Solo")
}

@Test func logCreatesTheFileThenAppendsToIt() throws {
    let url = URL.temporaryDirectory.appending(path: "continuity-test-\(UUID().uuidString).log")
    defer { try? FileManager.default.removeItem(at: url) }
    Feedback.log("done", for: "First", to: url)
    Feedback.log("done", for: "Second", to: url)
    let lines = try String(contentsOf: url, encoding: .utf8).split(separator: "\n")
    #expect(lines.count == 2)
    #expect(lines[0].hasSuffix("First — done"))
    #expect(lines[1].hasSuffix("Second — done"))
}
