# Pull Request Checker

This CLI utility is written for Lilly Together only. For usage, please [check here](USAGE.md).

This document describes the architecture design of this utility and its dependencies, and how they fit in the DIGHCI standard.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
## Contents

- [Architecture Overview](#architecture-overview)
  - [GitHub Actions workflow](#github-actions-workflow)
  - [CLI Utilities Invoked from GitHub Actions](#cli-utilities-invoked-from-github-actions)
  - [LillyUtilityCLI for Swift](#lillyutilitycli-for-swift)
- [Get Started](#get-started)
  - [Creating A CLI Utility Like This](#creating-a-cli-utility-like-this)
  - [CLI Arguments](#cli-arguments)
  - [Makefile](#makefile)
  - [Build The Project](#build-the-project)
- [Checks](#checks)
  - [PR Title, Git branch name, Git commit messages](#pr-title-git-branch-name-git-commit-messages)
  - [SwiftLint](#swiftlint)
  - [SwiftFormat](#swiftformat)
  - [Dependency Integrity Check](#dependency-integrity-check)
  - [Unit Testing](#unit-testing)
- [Error Handling](#error-handling)
  - [Exit Code](#exit-code)
  - [Posting PR Comments](#posting-pr-comments)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## Architecture Overview

As part of our CI/CD system, we are building tools those serve different purposes in different layers. In short:

- Workflow: what to do (interface)
- CLI utilities: how to do (implementation)
- Shared components: reusable libraries, frameworks / Swift packages, Ruby gems, etc.

### GitHub Actions workflow

These are YAML files that contains different jobs. [Examples](https://github.com/EliLillyCo/GCSP_VC_APP_IOS/tree/develop/.github/workflows):

- Pull request checker that runs automatically when a PR is updated.
- IPA builder that runs manually to generate artifacts for iOS distribution.

These workflow files should follow certain guidelines of DIGHCI.

### CLI Utilities Invoked from GitHub Actions

YAML workflow files invoke CLI utilities from a shell environment of a GitHub VM. These CLI utilities are project specific. [Examples](https://github.com/EliLillyCo/GCSP_VC_APP_IOS/tree/develop/DevOps/ci/script):

- Pull request title, Git branch name, Git commit messages check
- Pod integration check for iOS platform
- Unit testing

These CLI utilities are *not* designed to be reusable. Instead, they depend on open source and Lilly owned shared components. For example:

- Swift utilities depend on [the LillyUtilityCLI package](https://github.com/EliLillyCo/DIGH_LIFC_Utility/tree/develop/LillyUtilityCLI).
- Jenkins / Groovy scripts depend on [this Shared Library](https://github.com/EliLillyCo/CIRR_JenkinsPipelineLibraries).

### LillyUtilityCLI for Swift

As an example, for Swift based CLI utilities, [LillyUtilityCLI](https://github.com/EliLillyCo/DIGH_LIFC_Utility/tree/develop/LillyUtilityCLI) is designed to be reusable and testable, and provides features like regex pattern matching, shell commands execution and output pipes handling, Git helpers, etc.


## Get Started

This CLI utility checks a Lilly Together pull request when it's created / updated. Lilly Together is an iOS project, so this utility is written with Swift and managed by Swift Package Manager. This is recommended for all iOS / macOS projects. For other platforms, feel free to choose the technology you are comfortable with.

### Creating A CLI Utility Like This

To create a Swift CLI utility like this, follow [these steps](https://github.com/EliLillyCo/DIGH_LIFC_Utility/tree/develop/LillyUtilityCLI#how-to-create-a-cli-tool) and the [LillyUtilityCLISample](https://github.com/EliLillyCo/DIGH_LIFC_Utility/tree/develop/LillyUtilityCLI/LillyUtilityCLISample) Project.

### CLI Arguments

This utility uses [Swift Argument Parser](https://github.com/apple/swift-argument-parser) to parse arguments. By doing this, we can run the command with `--help` to get [all the arguments](USAGE.md). If you decide to use environment variables instead, please make them explicit in the source code and documentation.

### Makefile

You can either manage the product via Xcode, or use the `swift` CLI tool. Please check [this Makefile](Makefile) which wraps up some common build commands.

### Build The Project

Unlike Cocoapods, SPM projects typically don't commit dependencies. This will cause problem when cloning private repos like `LillyUtilityCLI` on GitHub VMs. As a workaround, you might commit the binary file built from local machine, but it is recommended to [contact the #DIGHCI team](https://elilillyco.slack.com/archives/GNB92AUUX) to add required credentials properly.


## Checks

For iOS projects, these checks are recommended:

### PR Title, Git branch name, Git commit messages

Lilly's Jira system enables a plugin that supports syncing GitHub PR, branches, and commits with Jira tickets. It is recommended to [set up GitHub](https://collab.lilly.com/sites/EIS_SEST_Team/Jira/Lists/Enterprise%20DOT%20%20JIRAGitHub%20Integration%20Request%20For/Request%20Complete%20%20N.aspx?viewpath=%2Fsites%2FEIS_SEST_Team%2FJira%2FLists%2FEnterprise%20DOT%20%20JIRAGitHub%20Integration%20Request%20For%2FRequest%20Complete%20%20N.aspx) to work with Jira. For more information, please [read here](https://elilillyco.slack.com/archives/C81PZU12Q/p1587742153024100).

The actual implementation about how GitHub info is synced with Jira may change. It is recommended to include Jira ticket number (e.g. LDV-1234, case sensitive) in PR titles, branch names, and commit messages.

Please check all `stringUtility.matches(str, pattern: Const.jiraPattern)` related code for implementation.

### SwiftLint

It is recommended to set up `SwiftLint` for iOS and macOS projects, so that we don't end up with huge functions, bad coding practice, and so on. It is also recommended to set up the linting rules you are comfortable with, and always commit to them. If there needs to be any exceptions, use `swiftlint:ignore` or alike, but never merge PRs with linting issues.

It is recommended to use `Pods/SwiftLint/swiftlint` instead of `brew install`, to make sure CI and developers are using the same tool.

`SwiftLint` always returns exit code 0. Error pipe are about linting rules, and they are ignored. Use standard pipe for human-friendly output.

### SwiftFormat

It is recommended to set up `SwiftFormat` for iOS and macOS projects, so that we don't have to write PR comments like "there should be 4 spaces instead of 5". There are multiple ways to set it up. In Lilly Together, we run `swiftformat` from Unit Tests, and before developer pushes his changes, he should test and format his code.

We don't want to commit any code changes from CI, so we use a `--lint` mode of `SwiftFormat`, which only checks if any formatting needs to be performed. `SwiftFormat` returns none 0 exit code, and error messages are in the error pipe.

It is recommended to use `Pods/SwiftFormat/CommandLineTool/swiftlint` instead of `brew install`, to make sure CI and developers are using the same tool.

### Dependency Integrity Check

Some projects are using source code based dependency management systems with best practice that encourages committing source code of the dependencies to the parent repo. For example, MMA iOS projects use Cocoapods and we don't `gitignore` our `Pods` directory. This ensures the project can always be built with certain build tools.

For such setup, it is recommended to deploy a check to make sure no changes are made to the local dependencies, because they are expected to be overwritten anytime. For Cocoapods based projects, we can use `LillyUtilityCLI.Git.checkPodIntegrity` function for such check.

### Unit Testing

It is recommended to run all unit tests on CI. It makes sure that:

- The product can be built and launched
- All unit tests are successful

However, it doesn't and shouldn't check:

- API services are working
- The app doesn't crash at a certain view

Lilly Together does not have integration tests / UI tests yet, but it is recommended to add them in CI checks.


## Error Handling

### Exit Code

As a general rule of all CLI utilities invoked from GitHub Action workflows, it is very important to properly return none 0 exit code. `Swift Argument Parser` automatically handles this when an error is thrown. Make sure to always test failure path, otherwise failed steps will be marked as success and it's very easy to miss them.

### Posting PR Comments

It is recommended to post meaningful logs to PR about failed checks, so that developers don't have to dig in GitHub Action logs. There are various ways to do this including using `curl` or the `gh pr comment` tool, etc.
