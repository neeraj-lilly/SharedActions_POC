import ArgumentParser
import LillyUtilityCLI
import Foundation
import MarkdownGenerator

/**
 * What this script checks
 *
 * [x] - PR title, branch name, commit messages: they should contain LDV-#### to meet Jira plugin requirements
 * [x] - PR message: should not contain PLACEHOLDER
 * [x] - Pods: no local Pods changes should be committed
 * [x] - SwiftFormat
 * [x] - SwiftLint
 * [x] - Unit tests
 * [ ] - Commit counts: should not be more than 1 commit per ?? KB code changes
 * UI tests is not enabled in this project
 * Checkmarks is handled in Jenkins differently
 */
struct PullRequestChecker: ParsableCommand, GitRequired, StringUtilityRequired, OSRequired {
    static var configuration = CommandConfiguration(
        abstract: "Pull request & code code for Lilly Together iOS.",
        version: "1.0.0"
    )

    @Argument(help: "The path of the Xcode project.")
    var path: String

    @Flag(name: .long, help: "Verbose mode.")
    var verbose: Bool = false

    @Flag(name: .long, help: "Skip unit tests.")
    var skipUnitTests: Bool = false

    @Flag(name: .long, help: "Enable Xcpretty.")
    var enableXcpretty: Bool = false

    @Option(name: .long, help: "Head branch.")
    var head: String = "HEAD"

    @Option(name: .long, help: "Base branch.")
    var base: String = "develop"

    @Option(name: .long, help: "Pull request title.")
    var prTitle: String

    @Option(name: .long, help: "Simulator name.")
    var simulatorName = "iPhone 12"

    @Option(name: .long, help: "Simulator OS.")
    var simulatorOS = "14.4"

    @Option(name: .long, help: "Post comments to pull request number, which can be obtained from ${{ github.event.pull_request.number }}.")
    var prNumber: Int?

    func run() throws {
        var details = [MarkdownConvertible]()
        log("---- begin ----")

        if !stringUtility.matches(prTitle, pattern: Const.jiraPattern) {
            log("PR title check failed - jira ticket")
            details.append(MarkdownHeader(title: "Invalid pull request title"))
            details.append("PR title '\(prTitle)' should match pattern `\(Const.jiraPattern)`")
        }
        if !stringUtility.matches(prTitle, pattern: Const.releaseTagPattern) {
            log("PR title check failed - release tag")
            details.append(MarkdownHeader(title: "Invalid pull request title"))
            details.append("PR title '\(prTitle)' should match pattern `\(Const.releaseTagPattern)`")
        }
        if !stringUtility.matches(head, pattern: Const.jiraPattern) {
            log("Branch name check failed")
            details.append(MarkdownHeader(title: "Invalid branch name"))
            details.append("Branch name '\(head)' should match pattern `\(Const.jiraPattern)`")
        }

        details += try checkCommitMessage()
        details += try checkSwiftLint()
        details += try checkSwiftFormat()
        if !skipUnitTests {
            if enableXcpretty {
                try os.shell("gem install xcpretty")
            }
            details += try runUnitTests()
        }

        if try !git.checkPodIntegrity(path: path, head: head, base: base) {
            details.append(MarkdownHeader(title: "Pod integrity check failed"))
            details.append("Do *NOT* make changes to local Pods directly. These changes are not managable in the long run.")
        }

        if details.isEmpty {
            print("Code check finished.")
            return
        }

        let result = MarkdownCollapsibleSection(summary: "Code check failed, please address the following issue(s) before merging.", details: details)
        log("---- output ----\n\(Const.Color.output)\(result.markdown)\(Const.Color.reset)")
        if let number = prNumber{
            try postComment(result.markdown, number: number)
        }
        log("----- end -----")
        throw CheckError.failure(reason: "Code check failed.")
    }

    private struct Const {
        static let jiraPattern = "(?=(LDV-\\d+))"
        static let releaseTagPattern = #"^R\d+\.\d+"#
        static let logFilename = "./_pr_log.txt"
        static let markdownCodeBlockLanguage = "console"

		struct Color {
			static let reset = "\u{001B}[m"
			static let lightCyan = "\u{001B}[1;36m"
			static let lightRed = "\u{001B}[1;31m"

			static let command = lightCyan
			static let output = lightRed
		}
    }

    private enum CheckError: Error {
        case failure(reason: String)
    }

    private func checkCommitMessage() throws -> [MarkdownConvertible] {
        let commits = try git.listCommits(fromBranch: base, toBranch: head).components(separatedBy: "\n")
        log("Commit check result: \(commits)")
        var items = [MarkdownConvertible]()
        commits.forEach { commit in
            if commit != "", !stringUtility.matches(commit, pattern: Const.jiraPattern) {
                items.append("Commit message '\(commit)' should match pattern \(Const.jiraPattern)")
            }
        }
        if items.isEmpty {
            return []
        } else {
            return [
                MarkdownHeader(title: "Invalid commit message(s)"),
                "The following commits should be rebased or amended:",
                MarkdownList(items: items),
            ]
        }
    }

    private func checkSwiftLint() throws -> [MarkdownConvertible] {
        let cmd = "cd \(path) && Pods/SwiftLint/swiftlint --quiet"
        log(message: "SwiftLint", command: cmd)
        // SwiftLint always returns exit code 0
        // Error outputs are about linting rules, and they are ignored
        let output = try os.shell(cmd, ignoreErrorOutput: true)
        if output.isEmpty {
            return []
        } else {
            return [
                MarkdownHeader(title: "SwiftLint failed"),
                "The following issue(s) should be addressed before merging:",
                MarkdownCodeBlock(code: output, style: .backticks(language: Const.markdownCodeBlockLanguage)),
            ]
        }
    }

    private func checkSwiftFormat() throws -> [MarkdownConvertible] {
        let excludePath = try os.absolutePath(relative: "\(path)/Pods")
        let cmd = "\(path)/Pods/SwiftFormat/CommandLineTool/swiftformat \(path)/ --exclude \(excludePath) --swiftversion 5.0.1 --wraparguments before-first --wrapcollections before-first --importgrouping testable-bottom --lint"
        log(message: "SwiftFormat", command: cmd)
        do {
            try os.shell(cmd, ignoreErrorOutput: true)
            log("SwiftFormat success.")
            return []
        } catch let OS.Error.processFailure(_, output, message) {
            // SwiftFormat returns none 0 exit code, and error messages are in the error pipe
            log("SwiftFormat standard output: \(output)")
            return [
                MarkdownHeader(title: "SwiftFormat linting failed"),
                "The following issue(s) should be addressed before merging:",
                MarkdownCodeBlock(code: message, style: .backticks(language: Const.markdownCodeBlockLanguage)),
                "Running unit tests to automatically apply SwiftFormat.",
            ]
        } catch let error {
            return [
                MarkdownHeader(title: "SwiftFormat linting failed with unexpected reason"),
                "Please contact #digh-ci channel on Slack to report this issue:",
                MarkdownCodeBlock(code: "Error: \(error)", style: .backticks(language: Const.markdownCodeBlockLanguage)),
            ]
        }
    }

    /// Running unit tests will perform SwiftFormat locally, so SwiftFormat lint should be performed before this step
    private func runUnitTests() throws -> [MarkdownConvertible] {
        log("Unit testing started...")
        do {
            var cmd = "xcodebuild -workspace \(path)/VirtualClaudia.xcworkspace -scheme LillyTogetherUSInternalQA -configuration DebugLillyTogetherUSInternalQA -sdk iphonesimulator -destination 'platform=iOS Simulator,name=\(simulatorName),OS=\(simulatorOS)' test"
            if enableXcpretty {
                cmd += " | xcpretty && exit ${PIPESTATUS[0]}"
            }
			log(message: "Unit tests", command: cmd)
            let output = try os.shell(cmd, ignoreErrorOutput: true)
            log("Unit tests standard output with exit code 0: \(output)")
            return []
        } catch let OS.Error.processFailure(_, output, message) {
            // xcodebuild returns none 0 exit code when there are build errors and/or failed test cases.
            // Build messages are in the standard pipe, and error messages are in the error pipe.
            log("Unit tests standard output: \(output)")
            log("Unit tests error output: \(message)")
            return [
                MarkdownHeader(title: "Unit tests failed"),
                "The following failed unit test(s) should be fixed before merging:",
                MarkdownCodeBlock(code: message, style: .backticks(language: Const.markdownCodeBlockLanguage)),
            ]
        } catch let error {
            return [
                MarkdownHeader(title: "Unit testing failed with unexpected reason"),
                "Please contact #digh-ci channel on Slack to report this issue:",
                MarkdownCodeBlock(code: "Error: \(error)", style: .backticks(language: Const.markdownCodeBlockLanguage)),
            ]
        }
    }

    private func postComment(_ contents: String, number: Int) throws {
        log("Post comment writing to: \(Const.logFilename):\n----\n\(contents)")
        do {
            let url = URL(fileURLWithPath: Const.logFilename)
            try contents.write(to: url, atomically: true, encoding: .utf8)
            log("Post comment wrote to file: \(url)")
            //let cmd = "curl -X POST ${{ github.event.pull_request.comments_url }} -H \"Content-Type: application/json\" -H 'Authorization: token ${{ secrets.gitCIToken }}' --data-binary '@ci-output-all.json'"
            let cmd = "gh pr comment \(number) --body-file \(Const.logFilename)"
			log(message: "Post comment", command: cmd)
            let output = try os.shell(cmd)
            log("Post comment output: \(output)")
        } catch let error {
            log("Post comment error: \(error)")
        }
    }

	// TODO: use `ConsoleLogger` from `LillyUtility/Logger`
    private func log(_ message: String) {
        guard verbose else {
            return
        }
        print("DEBUG " + message)
    }

	// TODO: color should be part of Logger
	private func log(message: String, command: String) {
		log("\(message) command: \(Const.Color.command)\(command)\(Const.Color.reset)")
	}
}

PullRequestChecker.main()
