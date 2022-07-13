import ArgumentParser
import LillyUtilityCLI
import Foundation
import MarkdownGenerator

enum ReleaseError: Error {
    case unknown(purpose: String)
    case notSupported(purpose: String)
    case emptyReleaseSummary
    case agvtoolFailure(output: String)
}

// TODO: we may want to introduce a `XcodeReleasable` protocol in LillyUtilityCLI
extension LillyTogetherReleaseType {
    var xcarchiveFilename: String { "output/\(rawValue).xcarchive" }

    var xcarchiveDescription: String { "\(rawValue) XCArchive" }
    var dsymsDescription: String { "\(rawValue) dSYMs" }
    var ipaDescription: String { "\(rawValue) IPA" }
    var ipaFilename: String { "\(name).ipa" }
}

// `ParsableCommand` is `Codable`; it's easier to make it not mutating at all.
struct Repository {
    static var releaseFilenames = [String]()
}

struct ArchiveRelease: ParsableCommand, GitRequired, StringUtilityRequired, OSRequired, XcodeRequired {
    static var configuration = CommandConfiguration(
        abstract: "Archive & release.",
        version: "0.0.1"
    )

    @Argument(help: "Purpose of the build, i.e. Release type.")
    var purpose: String

    @Flag(name: .long, help: "Verbose mode.")
    var verbose: Bool = false

    @Flag(name: .long, help: "Install provisioning profiles.")
    var installProfile: Bool = false

    @Flag(name: .long, help: "Install certificates to system keychain.")
    var installCertificate: Bool = false

    @Flag(name: .long, help: "Do NOT execute any shell command at all. Not supported by LillyUtilityCLI classes yet. DEBUG ONLY.")
    var dryRun: Bool = false

    @Flag(name: .long, help: "Create a mock archive instead of the real build to save time. DEBUG ONLY.")
    var mockArchive: Bool = false

    @Option(name: .long, help: "Root path of provisioning profiles.")
    var profileRoot: String = "./.github/secrets/"

    @Option(name: .long, help: "Plist file for export options. Required by exporting IPA.")
    var exportPlist: String?

    @Option(name: .long, help: "Xcode project path.")
    var projectPath: String = "."

    @Option(name: .long, help: "Release summary. Required by creating a release.")
    var releaseSummary: String?

    @Option(name: .long, help: "Marketing version.")
    var releaseVersion: String?

    @Option(name: .long, help: "Project version.")
    var releaseBuild: String?

    @Option(name: .long, help: "GitHub access token. Used in release notes generator.")
    var githubToken: String

    @Option(name: .long, help: "Release tag, e.g. R9.0. Used in release notes generator.")
    var releaseTag: String

    @Option(name: .long, help: "AppDyanmics account name. Must be stored in a secured vault.")
    var appdAccountName: String?

    @Option(name: .long, help: "AppDyanmics license key. Must be stored in a secured vault.")
    var appdLicenseKey: String?

    private struct Const {
        static let currentDate = Date()

        static let outputPath = "output"
        static let releaseNoteFilename = "\(outputPath)/release-notes"
        static let fullReleaseNoteFilename = "\(outputPath)/full-release-notes"
        static let ipaPath = "\(outputPath)/ipa"

        struct Color {
            static let reset = "\u{001B}[m"
            static let lightCyan = "\u{001B}[1;36m"
            static let lightRed = "\u{001B}[1;31m"

            static let command = lightCyan
            static let output = lightRed
        }
    }

    func run() throws {
        setupTerminalLogger()
        try execute("mkdir -p \(Const.outputPath)")
        try setVersions()
        guard let releaseType = LillyTogetherReleaseType(rawValue: purpose) else {
            print("ERROR unknown purpose; all supported cases:")
            LillyTogetherReleaseType.allCases.forEach { releaseType in
                print("\t\(releaseType.rawValue)")
            }
            throw ReleaseError.unknown(purpose: purpose)
        }
        try setupSecrets(releaseType: releaseType)
        try buildArchive(releaseType: releaseType)
        try exportIPA(releaseType: releaseType)
        try release(releaseType: releaseType)
        print("Released: \(releaseType)")
    }

    // MARK: - helpers

    private func log(_ message: String) {
        // TODO: use `ConsoleLogger` from `LillyUtility/Logger`
        guard verbose else {
            return
        }
        print("DEBUG " + message)
    }

    private func log(message: String, command: String) {
        log("\(message) command: \(Const.Color.command)\(command)\(Const.Color.reset)")
    }

    // Run and print log
    @discardableResult private func execute(_ cmd: String, message: String = "", ignoreErrorOutput: Bool = false, disableDryRun: Bool = false) throws -> String {
        log(message: message, command: cmd)
        let output: String
        if !dryRun || disableDryRun {
            output = try os.shell(cmd, ignoreErrorOutput: ignoreErrorOutput)
        } else {
            output = "DRY RUN"
        }
        log("\(message) output: \(Const.Color.output)\(output)\(Const.Color.reset)")
        return output
    }

    private func setVersions() throws {
        try xcode.setVersions(marketing: releaseVersion, project: releaseBuild, projectPath: projectPath)
    }

    // MARK: - secret management
    
    private func installProvisioningProfiles(profileType: String) throws {
        try xcode.installProvisioningProfiles(path: "\(profileRoot)/\(profileType)")
        try execute("ls ~/Library/MobileDevice/Provisioning\\ Profiles/", message: "Installed provioning profiles")
    }

    private func installCertificate(certContentName: String, certPasswordName: String) throws {
        try xcode.installCertificate(contentVariableName: certContentName, passwordVariableName: certPasswordName)
    }

    private func setupSecrets(releaseType: LillyTogetherReleaseType) throws {
        // Provisioning profile strategy by DIGHCI
        if installProfile {
            let type: String
            switch releaseType {
            case .usVendorQA:
                type = "development"
            case .usLillyQA, .usIVT, .usFBT, .usPenTest:
                type = "distribution"
            case .usAlpha:
                type = "com.lilly.study.lillytogether"
            case .usAppStore:
                type = "com.lilly.lillytogether"
            }
            try installProvisioningProfiles(profileType: type)
        }
        if installCertificate {
            let certContent: String
            let certPassword: String
            switch releaseType {
            case .usVendorQA:
                certContent = "CERT_IOS_DELOITTE_DEVELOP"
                certPassword = "CERT_IOS_DELOITTE_DEVELOP_PASSWORD"
            case .usLillyQA, .usIVT, .usFBT, .usPenTest, .usAppStore:
                // TODO: change LILLY_APPSTORE to LILLY_QA or alike
                certContent = "CERT_IOS_LILLY_APPSTORE_DISTRIBUTION"
                certPassword = "CERT_IOS_LILLY_APPSTORE_DISTRIBUTION_PASSWORD"
            case .usAlpha:
                certContent = "CERT_IOS_LILLY_ENTERPRISE_DEVELOP"
                certPassword = "CERT_IOS_LILLY_ENTERPRISE_DEVELOP_PASSWORD"
            }
            try installCertificate(certContentName: certContent, certPasswordName: certPassword)
        }
    }

    // MARK: - archive and export

    private func buildArchive(releaseType: LillyTogetherReleaseType) throws {
        let xcarchiveZip = try xcarchiveZipFilename(releaseType: releaseType)
        let dsymsZip = try dsymsZipFilename(releaseType: releaseType)
        let appDsymZip = try appDsymZipFilename(releaseType: releaseType)

        // Debug code
        if mockArchive {
            try execute("echo test > \(xcarchiveZip)", message: "create mock release")
            try execute("echo test > \(dsymsZip)", message: "create mock dSYMs")
            return
        }

        let artifacts = try xcode.buildArchive(
            workspace: "\(projectPath)/VirtualClaudia.xcworkspace",
            releaseType: releaseType,
            xcarchiveFilename: releaseType.xcarchiveFilename,
            xcarchiveZipFilename: xcarchiveZip,
            dsymsZipFilename: dsymsZip,
            appDsymZipFilename: appDsymZip,
            installXcpretty: true
        )
        Repository.releaseFilenames += artifacts

        // Upload dSYMs right now, even though the following steps may fail.
        // This behavior may need to be optimized in future.
        if let accountName = appdAccountName, let licenseKey = appdLicenseKey {
            try AppDynamics.uploadDsym(
                filenames: [
                    dsymsZip,
                    appDsymZip,
                ],
                accountName: accountName,
                licenseKey: licenseKey
            )
        }
    }

    private func exportIPA(releaseType: LillyTogetherReleaseType) throws {
        guard releaseType != .usAppStore else {
            log("Export is disabled for production builds. Skipping export process.")
            return
        }
        guard releaseType != .usAlpha else {
            log("Export is disabled for enterprise builds. Skipping export process.")
            return
        }
        guard let plist = exportPlist else {
            log("No exportOptionsPlist filename specified, skipping export process. See --help for more info.")
            return
        }
        try xcode.exportIPA(
            xcarchiveFilename: releaseType.xcarchiveFilename,
            exportPlist: plist,
            ipaPath: Const.ipaPath
        )
        Repository.releaseFilenames.append("\(Const.ipaPath)/\(releaseType.ipaFilename)#\(releaseType.ipaDescription)")
    }

    // MARK: - GitHub release

    /// Marketing version string; could be throwable computed property in Swift 5.5 from SE-0310
    private func getVersion() throws -> String {
        if let version = releaseVersion, !version.isEmpty {
            return version
        } else {
            let output = try execute("cd \(projectPath) && agvtool what-marketing-version -terse1", message: "get marketing version", ignoreErrorOutput: true, disableDryRun: true)
            let components = output.components(separatedBy: "\n")
            guard !components.isEmpty else {
                throw ReleaseError.agvtoolFailure(output: output)
            }
            return components[0]
        }
    }

    /// Project version number string
    private func getBuild() throws -> String {
        if let build = releaseBuild, !build.isEmpty {
            return build
        } else {
            let output = try execute("cd \(projectPath) && agvtool what-version -terse", message: "get project version", ignoreErrorOutput: true, disableDryRun: true)
            let components = output.components(separatedBy: "\n")
            guard !components.isEmpty else {
                throw ReleaseError.agvtoolFailure(output: output)
            }
            return components[0]
        }
    }

    private func releaseTagPrefix(releaseType: LillyTogetherReleaseType, previousIndex: Int = 0) throws -> String {
        let version = try getVersion()
        var build = try getBuild()

        if let buildNumber = Int(build) {
            build = String(buildNumber - previousIndex)
        }
        return "v\(version)_\(build)"
    }

    private func releaseTag(releaseType: LillyTogetherReleaseType) throws -> String {
        let prefix = try releaseTagPrefix(releaseType: releaseType)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return "\(prefix)_\(releaseType.rawValue)_\(formatter.string(from: Const.currentDate))"
    }

    private func xcarchiveZipFilename(releaseType: LillyTogetherReleaseType) throws -> String {
        return try "\(Const.outputPath)/" + releaseTag(releaseType: releaseType) + ".xcarchive.zip"
    }

    private func dsymsZipFilename(releaseType: LillyTogetherReleaseType) throws -> String {
        return try "\(Const.outputPath)/" + releaseTag(releaseType: releaseType) + ".dsyms.zip"
    }

    private func appDsymZipFilename(releaseType: LillyTogetherReleaseType) throws -> String {
        return try "\(Const.outputPath)/" + releaseTag(releaseType: releaseType) + ".app.dsym.zip"
    }

    private func release(releaseType: LillyTogetherReleaseType) throws {
        guard let summary = releaseSummary else {
            log("No release summary, skipping release process. See --help for more info.")
            return
        }
        guard !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("Non-empty release summary is mandatory for GitHub release. Remove the argument if you don't want to create a release.")
            throw ReleaseError.emptyReleaseSummary
        }

        try createReleaseNote(releaseType: releaseType, summary: summary)

        let tag = try releaseTag(releaseType: releaseType)
        let files = "'" + Repository.releaseFilenames.joined(separator: "' '") + "'"
        try execute("gh release create \(tag) \(files) --prerelease --title 'Automated Release \(tag)' --notes-file '\(Const.releaseNoteFilename).md'", message: "create release")
    }

    private func getPreviousRelease(releaseType: LillyTogetherReleaseType) throws -> String? {
        let prefix = try releaseTagPrefix(releaseType: releaseType, previousIndex: 1)
        let tags = try execute("git --no-pager tag -l | sort -rV", disableDryRun: true)
        log("Finding '\(prefix)' from tags (size: \(tags.count))")
        for tag in tags.split(whereSeparator: \.isNewline) {
            let tagString = String(tag)
            if tagString.contains(prefix) {
                return tagString
            }
        }
        return nil
    }

    private func createReleaseNote(releaseType: LillyTogetherReleaseType, summary: String) throws {
        let github = GitHub(token: githubToken, username: "EliLillyCo", repoName: "GCSP_VC_APP_IOS")
        let generator = try ReleaseNoteGenerator(
            summary: summary,
            version: try getVersion(),
            build: try getBuild(),
            date: Const.currentDate,
            releaseType: releaseType,
            github: github,
            releaseTag: releaseTag
        )
        let notes = try generator.generateMarkdown()

        let shortNotes: String
        if notes.components(separatedBy: "\n").count > 500 {
            shortNotes = stringUtility.linesOf(string: notes, range: 0 ..< 500) + "\n\n**IMPORTANT**: This changelog has been truncated due to the size limitation of GitHub releases. Please download the Full Release Notes from Assets below.\n"
        } else {
            shortNotes = notes
        }
        log("Short notes length: \(shortNotes.components(separatedBy: "\n").count)")
        log("Full notes length: \(notes.components(separatedBy: "\n").count)")
        log("Short notes size: \(shortNotes.count)")
        log("Full notes size: \(notes.count)")

        let file = MarkdownFile(filename: Const.releaseNoteFilename, basePath: ".", content: shortNotes)
        try file.write()

        let fullFile = MarkdownFile(filename: Const.fullReleaseNoteFilename, basePath: ".", content: notes)
        try fullFile.write()

        Repository.releaseFilenames.append("\(Const.fullReleaseNoteFilename).md#Full Release Notes")
    }

    /// Setup a shared `TerminalLogger`
    private func setupTerminalLogger() {
        let config: LoggerConfiguration = DefaultLoggerConfiguration(
            subsystem: "Release",
            category: "CLI",
            defaultType: .info,
            //verboseLevel: verbose ? .verbose : .none
            enabledForRelease: verbose
        )
        LoggerManager().setup(loggers: [
            TerminalLogger(configuration: config),
        ])
    }
}

ArchiveRelease.main()
