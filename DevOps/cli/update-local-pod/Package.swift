// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LocalPodUpdater",
	platforms: [
        .macOS(.v10_12)
    ],
    products: [
        .executable(name: "update-local-pod", targets: ["LocalPodUpdater"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(
            url: "https://github.com/apple/swift-argument-parser", 
            .upToNextMinor(from: "0.3.0")
        ),
        Package.Dependency.package(
			name: "LillyUtilityCLI", // <- Leo: Not sure why this is needed, help?
			url: "git@github.com:EliLillyCo/DIGH_LIFC_Utility.git", 
			.revision("41304478a7b299d070882dc5d6e5773b8e6f8318") // <- updated API in 9/15
			//path: "../../../../lilly-utility/"
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "LocalPodUpdater",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
                .product(
                    name: "LillyUtilityCLI",
                    package: "LillyUtilityCLI"
                ),
            ]
        ),
        .testTarget(
            name: "LocalPodUpdaterTests",
            dependencies: ["LocalPodUpdater"]
        ),
    ]
)
