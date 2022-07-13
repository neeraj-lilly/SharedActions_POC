#!/usr/bin/swift
// vim: autoindent:cindent:ts=4:sw=4:sts=4

import Foundation

/// Environment

protocol Environment {
    var title: String { get }
}

struct ParamEnvironment: Environment {
    let title = CommandLine.arguments[2]
}

struct JenkinsEnvironment: Environment {
    var title: String {
        guard let title = ProcessInfo.processInfo.environment["CHANGE_TITLE"] else {
            print("WARNING empty title, aborting; please contact #digh-ci on Slack")
            exit(1)
        }
        return title
    }
}

struct TestEnvironment: Environment {
    let title = "r1.0"
    // let title = "R1.2.3"
    // let title = "R3.0 LDV-1234"
    // let title = "LDV-012 R 10"
}

let env: Environment = ParamEnvironment()
// let env: Environment = TestEnvironment(); print("WARNING: do NOT commit your code if you see this!!!\n----")

/// CLI

guard CommandLine.arguments.count == 3 else {
    print("This script checks whether title of the GitHub PR matches a given Regex pattern. https://dot-jira.lilly.com/browse/LDV-3730")
    print("Usage: \(CommandLine.arguments[0]) {PATTERN} {Title}")
    print("Examples:")
    print("\t\(CommandLine.arguments[0]) R(\\d+\\.)?(\\d+\\.)?(\\*|\\d+) 'R3.0 LDV-1234 Updated comments' - Make sure a 'R2.0' or 'R3.0.1' is included in title")
    exit(-1)
}

let kPattern = CommandLine.arguments[1]

func shell(_ command: String) -> String? {
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c", command]

    let pipe = Pipe()
    task.standardOutput = pipe
    task.launch()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8)
}

/// Matching

func containsPattern(_ str: String) -> Bool {
    return str.range(of: kPattern, options: .regularExpression) != nil
}

/// Checkers

// Always returns `true` because PRs will be linked with Jira as long as branch is linked.
func checkPRTitle() -> Bool {
    return containsPattern(env.title)
}

/// Main

func main() -> Bool {
    var success = true
    if checkPRTitle() {
        print("PR title pattern check success")
    } else {
        print("ERROR PR title check failed: title '\(env.title)' does not contain pattern '\(kPattern)'; please edit PR title.")
        success = false
    }

    return success
}

if main() {
    print("PR title check success")
} else {
    print("PR title check failed")
    exit(1)
}
