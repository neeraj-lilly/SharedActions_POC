import ArgumentParser
import LillyUtilityCLI
import Foundation

struct DocumentGeneratorExample: ParsableCommand, GitRequired, OSRequired, Loggable {
    private enum Error: Swift.Error {
        case additionalLicenseMismatch
        case agvtoolFailure(output: String)
    }

	private struct Const {
        static let currentDate = Date()

		static let designSpec = "DesignSpecAppx"
		static let lpReleaseType = "ReleaseTypes"
		static let coreData = "CoreData"
		static let coreDataCSVs = "CoreDataSpreadsheets"
		static let dependency = "FrameworksAndDependencies"
		static let thirdPartyDependency = "ThirdPartyDependencies"
		static let networkingError = "NetworkingErrors"
		static let license = "ThirdPartyLicenses"
		static let releaseNotes = "ReleaseNotes"
	}

    static var configuration = CommandConfiguration(
        abstract: "Document generators for Lilly Together.",
        version: "0.0.1"
	)

    @Flag(name: .long, help: "Install dependencies, e.g. `brew install xmlstarlet`.")
    var installDependency = false

    @Option(name: .long, help: "Xcode project path.")
    var projectPath: String

    @Option(name: .long, help: "CoreData path.")
    var coreDataPath: String

    @Option(name: .long, help: "Path of Podfile and Podfile.lock.")
    var podfilePath: String

    @Option(name: .long, help: "Output path.")
    var outputPath: String = "."

    @Option(name: .long, help: "CSS filename.")
    var cssFilename: String?

    @Option(name: .long, help: "Additional license owner(s). Must match --additiona-license-filename.")
    var additionalLicenseOwner: [String] = [String]()

    @Option(name: .long, help: "Additional license filename(s). Must match --additiona-license-owner.")
    var additionalLicenseFilename: [String] = [String]()

    @Option(name: .long, help: "Release tag, e.g. R9.0. Used in release notes generator.")
    var releaseTag: String?

    func run() throws {
        LoggerManager().setup(loggers: [
            TerminalLogger(),
        ])
		if installDependency {
			// "dependencies already installed" errors will be ignored
			let cmd = "brew install xmlstarlet"
			log("Installing dependencies: \(cmd)")
			let output = try? os.shell(cmd)
			log("Result: \(output ?? "N/A")")
		}
		try generateDesignSpec()
		try generateLPReleaseType()
		try generateCoreData()
		try generateCoreDataCSV()
		try generateAllDependency()
		try generateThirdPartyDependency()
		try generateNetworkingError()
		try generateLicense()
        //try generateReleaseNotes()
    }

	private func generateDesignSpec() throws {
		let generator = try DesignSpecGenerator(path: projectPath)
		try generator.writeMarkdown(filename: "\(outputPath)/\(Const.designSpec)")
		//print("\nPreview: design spec\n________")
		//print(try generator.generateMarkdown())
	}

	private func generateLPReleaseType() throws {
		let generator = LillyTogetherReleaseType.usVendorQA
		try generator.writeMarkdown(filename: "\(outputPath)/\(Const.lpReleaseType)")
		//print("\nPreview: LillyTogether Release Type\n________")
		//print(try generator.generateMarkdown())
	}

	private func generateCoreData() throws {
        // TODO: read from info.plist
		let generator = try CoreDataGenerator(path: coreDataPath, appVersion: "9.0.0")
		try generator.writeMarkdown(filename: "\(outputPath)/\(Const.coreData)")
	}

	private func generateCoreDataCSV() throws {
		let dest = "\(outputPath)/\(Const.coreDataCSVs)"
		try CoreDataModelSpreadsheetsGenerator.writeAllCSVs(inputPath: coreDataPath, outputFilename: dest, outputTypes: [.csv])
	}

	private func generateAllDependency() throws {
		let generator = try DependencyGenerator(path: podfilePath)
		try generator.writeMarkdown(filename: "\(outputPath)/\(Const.dependency)")
		try generator.writeHTML(filename: "\(outputPath)/\(Const.dependency)")
	}

	private func generateThirdPartyDependency() throws {
        var css: String?
        if let filename = cssFilename {
            css = try String(contentsOfFile: filename)
        }
		let generator = try ThirdPartyDependencyGenerator(path: podfilePath)
		try generator.writeMarkdown(filename: "\(outputPath)/\(Const.thirdPartyDependency)")
		try generator.writeHTML(filename: "\(outputPath)/\(Const.thirdPartyDependency)", insertCSS: css, insertHead: "<br>")
	}

	private func generateNetworkingError() throws {
		let generator = NetworkingErrorGenerator()
		try generator.writeMarkdown(filename: "\(outputPath)/\(Const.networkingError)")
	}

	private func generateLicense() throws {
        guard additionalLicenseOwner.count == additionalLicenseFilename.count else {
            throw Error.additionalLicenseMismatch
        }

        var licenses = [LicenseGenerator.License]()
        for index in 0 ..< additionalLicenseOwner.count {
            licenses.append(LicenseGenerator.License(
                owner: additionalLicenseOwner[index],
                filename: additionalLicenseFilename[index]
            ))
        }

        // Podfile and Pods are always in the same path (?)
        let generator = try LicenseGenerator(path: podfilePath, additionalLicenses: licenses)
		try generator.writeMarkdown(filename: "\(outputPath)/\(Const.license)")
		try generator.writePDF(filename: "\(outputPath)/\(Const.license)")
	}

    /// Unlike other functions, this one need to be manually updated. 
    /// Check local variables for details.
    private func generateReleaseNotes() throws {
        /*
        let releaseType = LillyTogetherReleaseType.usAppStore
        let summary = "This release note is generated by [DocumentGenerator](../../DevOps/cli/generate-documents)."
        let github = GitHub(token: "TODO: github token here", username: "EliLillyCo", repoName: "GCSP_VC_APP_IOS")
        let generator = try ReleaseNoteGenerator(
            summary: summary,
            version: try getVersion(),
            build: try getBuild(),
            date: Const.currentDate,
            releaseType: releaseType,
            github: github,
            releaseTag: releaseTag ?? "TODO: release tag here"
        )
        try generator.writeMarkdown(filename: "\(outputPath)/\(Const.releaseNotes)")
        let notes = try generator.generateMarkdown()

        let file = MarkdownFile(filename: "\(outputPath)/\(Const.releaseNotes)", basePath: ".", content: notes)
        try file.write()
        */
    }

    /// Marketing version string; could be throwable computed property in Swift 5.5 from SE-0310
    private func getVersion() throws -> String {
        let output = try os.shell("cd \(podfilePath) && agvtool what-marketing-version -terse1", ignoreErrorOutput: true)
        let components = output.components(separatedBy: "\n")
        guard !components.isEmpty else {
            throw Error.agvtoolFailure(output: output)
        }
        return components[0]
    }

    /// Project version number string
    private func getBuild() throws -> String {
        let output = try os.shell("cd \(podfilePath) && agvtool what-version -terse", ignoreErrorOutput: true)
        let components = output.components(separatedBy: "\n")
        guard !components.isEmpty else {
            throw Error.agvtoolFailure(output: output)
        }
        return components[0]
    }
}

DocumentGeneratorExample.main()
