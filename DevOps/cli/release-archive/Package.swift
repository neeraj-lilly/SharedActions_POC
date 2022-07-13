// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ArchiveRelease",
	platforms: [
        .macOS(.v10_12)
    ],
    products: [
        .executable(name: "release-archive", targets: ["ArchiveRelease"])
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
			.revision("3ccc7b1e900e81d94a3e4fc7934265b94c0fb326") // <- API update on 03/30
			//path: "../../../../lilly-utility/"
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ArchiveRelease",
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
            name: "ArchiveReleaseTests",
            dependencies: ["ArchiveRelease"]
        ),
    ]
)
