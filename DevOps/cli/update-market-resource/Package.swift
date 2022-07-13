// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let packageCLIGit = Package.Dependency.package(
    name: "LillyUtilityCLI", // <- Not sure why this is needed, help?
    url: "https://github.com/EliLillyCo/DIGH_LIFC_Utility", 
    .revision("a41cae4367edf970cb03fb19eebb3679ca0229b0")
)
let packageCLILocal = Package.Dependency.package(
    name: "LillyUtilityCLI", // <- Not sure why this is needed, help?
    path: "../../"
)
//let packageCLI = packageCLILocal
let packageCLI = packageCLIGit

let package = Package(
    name: "MarketResourceUpdater",
    platforms: [
        .macOS(.v10_12),
    ],
    products: [
        .executable(name: "update-market-resource", targets: ["MarketResourceUpdater"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(
            url: "https://github.com/apple/swift-argument-parser", 
            .upToNextMinor(from: "0.3.0")
        ),
        packageCLI,
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "MarketResourceUpdater",
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
            name: "MarketResourceUpdaterTests",
            dependencies: ["MarketResourceUpdater"]
        ),
    ]
)
