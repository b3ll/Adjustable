// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Adjustable",
    platforms: [
        .iOS(.v17),
        .tvOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "Adjustable",
            targets: ["Adjustable"]),
    ],
    dependencies: [
        .package(url: "https://github.com/b3ll/Motion", .upToNextMajor(from: "0.1.5")),
    ],
    targets: [
        .target(
            name: "Adjustable",
            dependencies: ["Motion"]),
    ],
    swiftLanguageVersions: [.v5]
)
