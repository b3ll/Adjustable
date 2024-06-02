// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DebugAdjustable",
    platforms: [
        .iOS(.v17),
        .tvOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "DebugAdjustable",
            targets: ["DebugAdjustable"]),
    ],
    dependencies: [
        .package(url: "https://github.com/b3ll/Motion", .upToNextMajor(from: "0.1.5")),
    ],
    targets: [
        .target(
            name: "DebugAdjustable",
            dependencies: ["Motion"]),
    ],
    swiftLanguageVersions: [.v5]
)
