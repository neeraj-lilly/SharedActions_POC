// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DocumentGenerator",
    platforms: [
        .macOS(.v10_12),
    ],
    products: [
        .executable(name: "generate-documents", targets: ["DocumentGenerator"])
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
            url: "https://github.com/EliLillyCo/DIGH_LIFC_Utility", 
            .revision("955d7b2e4aaa053bbc4c048e44a69369728a6ed1") // <- api update on 6/16
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "DocumentGenerator",
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
            name: "DocumentGeneratorTests",
            dependencies: ["DocumentGenerator"]
        ),
    ]
)
