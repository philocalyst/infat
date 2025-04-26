// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "infat",
    platforms: [
        .macOS(.v13)
    ],

    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", exact: "1.2.0"),
        .package(url: "https://github.com/apple/swift-log.git", exact: "1.5.3"),
        .package(url: "https://github.com/orchetect/PListKit", exact: "2.0.3"),
        .package(url: "https://github.com/jdfergason/swift-toml", exact: "1.0.0"),
        .package(url: "https://github.com/mtynior/ColorizeSwift.git", exact: "1.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "infat",
            dependencies: [
                .product(name: "PListKit", package: "PListKit"),
                .product(name: "Toml", package: "swift-toml"),
                "ColorizeSwift",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
            ]
        )
    ]
)
