#!/usr/bin/swift
// vim: autoindent:cindent:ts=4:sw=4:sts=4

import Foundation

/// Environment

protocol Environment {
    var title: String { get }
    var branch: String { get }
    var mergeFrom: String { get }
    var mergeTo: String { get }
}

struct GitHubEnvironment: Environment {
    var title: String {
        guard let title = ProcessInfo.processInfo.environment["{ github.event.pull_request.title }"] else {
            print("WARNING empty title, aborting; please contact #digh-ci on Slack")
            exit(1)
        }
        return title
    }

    var branch: String {
        guard let branch = ProcessInfo.processInfo.environment["GITHUB_HEAD_REF"] else {
            print("WARNING empty branch, aborting; please contact #digh-ci on Slack")
            exit(1)
        }
        return branch
    }

    var mergeFrom: String {
        guard let branch = ProcessInfo.processInfo.environment["GITHUB_HEAD_REF"] else {
            print("WARNING empty branch, aborting; please contact #digh-ci on Slack")
            exit(1)
        }
        return "remotes/origin/\(branch)"
    }

    var mergeTo: String {
        guard let target = ProcessInfo.processInfo.environment["GITHUB_BASE_REF"] else {
            print("WARNING empty target, aborting; please contact #digh-ci on Slack")
            exit(1)
        }
        return "remotes/origin/\(target)"
    }
}

struct JenkinsEnvironment: Environment {
    var title: String {
        guard let title = ProcessInfo.processInfo.environment["CHANGE_TITLE"] else {
            print("WARNING empty title, aborting; please contact #digh-ci on Slack")
            exit(1)
        }
        return title
    }

    var branch: String {
        guard let branch = ProcessInfo.processInfo.environment["GITHUB_HEAD_REFCHANGE_BRANCH"] else {
            print("WARNING empty branch, aborting; please contact #digh-ci on Slack")
            exit(1)
        }
        return branch
    }

    var mergeFrom: String {
        guard let branch = ProcessInfo.processInfo.environment["BRANCH_NAME"] else {
            print("WARNING empty branch, aborting; please contact #digh-ci on Slack")
            exit(1)
        }
        return "remotes/origin/\(branch)"
    }

    var mergeTo: String {
        guard let target = ProcessInfo.processInfo.environment["CHANGE_TARGET"] else {
            print("WARNING empty target, aborting; please contact #digh-ci on Slack")
            exit(1)
        }
        return "remotes/origin/\(target)"
    }
}

struct TestEnvironment: Environment {
    let title = "LDV-1234"

    // let branch = "feature/LDV-12-test"
    let branch = "feature/LDV-12-test"

    let mergeFrom = "feature/LDV-3702-jira-checker"
    let mergeTo = "develop"
}

let env: Environment = GitHubEnvironment()
// let env: Environment = TestEnvironment(); print("WARNING: do NOT commit your code if you see this!!!\n----")

/// CLI

guard CommandLine.arguments.count == 2 else {
    print("This script checks whether naming convention of GitHub PR, branch, and commits is compatible with Jira plugin. https://dot-jira.lilly.com/browse/LDV-3702")
    print("Usage: \(CommandLine.arguments[0]) {JIRA_PREFIX}")
    print("Examples:")
    print("\t\(CommandLine.arguments[0]) LDV")
    exit(-1)
}

let kDirProjectPrefix = CommandLine.arguments[1]
let kJiraRegex = "\(kDirProjectPrefix)\\-\\d+"

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

func containsJiraTicket(_ str: String) -> Bool {
    return str.range(of: kJiraRegex, options: .regularExpression) != nil
}

/// Checkers

// Always returns `true` because PRs will be linked with Jira as long as branch is linked.
func checkPR() -> Bool {
    return containsJiraTicket(env.title)
}

// Returns `true` if branch name contains `LDV-####`
func checkBranch() -> Bool {
    return containsJiraTicket(env.branch)
}

func checkCommits() -> Bool {
    var success = true

    let cmd = "git --no-pager log --pretty=oneline \(env.mergeTo)..\(env.mergeFrom)"
    // print("DEBUG cmd: \(cmd)")
    guard let output = shell(cmd) else {
        print("WARNING empty results, aborting: \(cmd)")
        exit(1)
    }
    // print("DEBUG output: \(output)")

    let commits = output.split { $0.isNewline }
    commits.forEach { commit in
        // print("DEBUG commit: \(commit)")
        if !containsJiraTicket(String(commit)) {
            print("WARNING commit message '\(commit)' does not contain pattern '\(kJiraRegex)'")
            success = false
        }
    }
    return success
}

/// Main

func main() -> Bool {
    var success = true
    /*
     if checkPR() {
         print("PR check success - not working properly; having trouble getting PR title")
     } else {
         print("ERROR PR check failed: title '\(env.title)' does not contain pattern '\(kJiraRegex)'; please edit PR title.")
         success = false
     }
     */

    if checkBranch() {
        print("Branch check success")
    } else {
        print("ERROR Branch check failed: branch '\(env.branch)' does not contain pattern '\(kJiraRegex)'; please create a new branch, close this PR, and start a new PR with the new branch.")
        success = false
    }

    if checkCommits() {
        print("Commits check success")
    } else {
        print("ERROR Commits check failed: not all commit messages contain pattern '\(kJiraRegex)'; please consider amending / rebasing your PR")
        success = false
    }

    return success
}

if main() {
    print("Jira plugin check success")
} else {
    print("Jira plugin check failed")
    exit(1)
}
