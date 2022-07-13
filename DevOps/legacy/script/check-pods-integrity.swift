#!/usr/bin/swift
// vim: noai:ts=4:sw=4

import Foundation

guard CommandLine.arguments.count == 2 else {
    print("This script checks undesired changes in Pods directory.")
    print("Usage: \(CommandLine.arguments[0]) {APP_ROOT_DIR}")
    print("Examples:")
    print("\tIf your app's project is at root level: \(CommandLine.arguments[0]) .")
    print("\tIf your app is in a subdirectory: \(CommandLine.arguments[0]) VirtualClaudia")
    exit(-1)
}

let kDirProjectPrefix = CommandLine.arguments[1] + "/"

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

// Returns `true` if integrity check passes
func checkIntegrity() -> Bool {
    let kDirPods = kDirProjectPrefix + "Pods/"
    let kFilenamePodsProject = kDirProjectPrefix + "Pods/Pods.xcodeproj/project.pbxproj"
    let kFilenamePodfileLock = kDirProjectPrefix + "Podfile.lock"

    // Test code
    /*
     let target = "develop"
     let remoteBranch = "bugfix/LDV-3613-devops-local-pod-test"
      */

    // Jenkins env
    guard let target = ProcessInfo.processInfo.environment["GITHUB_BASE_REF"] else {
        print("WARNING empty target, aborting - please contact #digh-ci channel")
        return false
    }
    guard let branch = ProcessInfo.processInfo.environment["GITHUB_HEAD_REF"] else {
        print("WARNING empty target, aborting - please contact #digh-ci channel")
        return false
    }
    let remoteBranch = "remotes/origin/\(branch)"

    let cmd = "git --no-pager diff --name-status remotes/origin/\(target)..\(remoteBranch)"
    guard let output = shell(cmd) else {
        print("WARNING empty results, aborting: \(cmd) - please contact #digh-ci channel")
        return false
    }

    // print("\(target) \(branch)")
    print("Command: \(cmd)")
    print("Output:\n\(output)")

    // `git diff` contains "Pods" change, but "Podfile.lock" is not updated:
    // need to check further
    if !output.contains(kFilenamePodfileLock), output.contains(kDirPods) {
        print("INFO changes in Pods detected, and Podfile.lock is not updated")
        // `git diff` only contains "Pods/Pods.xcodeproj/project.pbxproj" change:
        // likely to be local pod change like adding file(s) to a local pod
        // then run `pod install`, which is fine.
        // Details: https://dot-jira.lilly.com/browse/LDV-3613
        if output.contains(kFilenamePodsProject), !output.replacingOccurrences(of: kFilenamePodsProject, with: "").contains(kDirPods) {
            print("INFO Pods project file is changed, and there's no other Pod changes")
            return true
        } else {
            return false
        }
    }
    return true
}

if checkIntegrity() {
    print("Pods integrity check success")
} else {
    print("ERROR Pods integrity check fails: changes under \(kDirProjectPrefix)Pods/ but Podfile.lock is not updated")
    exit(1)
}
