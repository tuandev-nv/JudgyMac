// swift-tools-version: 6.0
// This Package.swift is for build verification only.
// The actual app uses an Xcode project with MenuBarExtra.

import PackageDescription

let package = Package(
    name: "JudgyMac",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "JudgyMac",
            path: "JudgyMac",
            exclude: ["Resources"]
        ),
    ]
)
