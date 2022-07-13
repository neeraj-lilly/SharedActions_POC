import ArgumentParser
import LillyUtilityCLI
import Foundation

struct LocalPodUpdater: ParsableCommand, Loggable, OSRequired {
    enum Error: Swift.Error {
        case mismatchedArguments
        case invalid(hash: String)
    }

    static var configuration = CommandConfiguration(
        abstract: "Update files in local pods.",
        version: "1.0.0"
    )

    @Argument(help: "The path of the Xcode project, which contains 'Podfile.lock'.")
    var path: String

    @Flag(name: .long, help: "Verbose mode.")
    var verbose: Bool = false

    @Option(name: .long, help: "Git hashes. Can contain leading Podfile.lock style string '$POD: '. Can be multiple. Must match other arguments. At list one group is required.")
    var gitHash: [String]

    @Option(name: .long, help: "Input filenames, typically in '$CLI/Assets' directory. Can be multiple. Must match other arguments.")
    var inputFilename: [String]

    @Option(name: .long, help: "Output filenames, typically in '$PROJECT/Pods/$POD' directory. Must be full path. Can be multiple. Must match other arguments.")
    var outputFilename: [String]

    func run() throws {
        LoggerManager().setup(loggers: [
            TerminalLogger(),
        ])
        log("---- begin updating local pods ----")
        guard gitHash.count == inputFilename.count, gitHash.count == outputFilename.count else {
            log("Make sure the counts of all array type arguments match each other. Please note that orders *DO* matter.", type: .fault)
            throw Error.mismatchedArguments
        }
        let lockContents = try String(contentsOfFile: "\(path)/Podfile.lock")
        for index in 0 ..< gitHash.count {
            let hash = gitHash[index]
            guard lockContents.contains(hash) else {
                log("Git hash \(hash) is invalid, it is likely that the dependency has been updated. Please make sure your local fix is still needed, then update the parameters of this CLI tool inside your Podfile.", type: .fault)
                throw Error.invalid(hash: hash)
            }

            let input = inputFilename[index]
            let output = outputFilename[index]
            try os.shell("cp -f \(input) \(output)")
            if verbose {
                log("\(input) has been updated, diff:\n")
                try os.shell("git diff \(output)")
            }
        }
        print("Done.")
    }
}

LocalPodUpdater.main()
