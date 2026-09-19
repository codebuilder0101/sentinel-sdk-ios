// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SentinelSDK",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "SentinelSDK",
            targets: ["SentinelSDK"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SentinelSDK",
            dependencies: [],
            path: "Sources/SentinelSDK",
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "SentinelSDKTests",
            dependencies: ["SentinelSDK"],
            path: "Tests/SentinelSDKTests"
        ),
    ]
)
