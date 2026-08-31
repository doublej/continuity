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
