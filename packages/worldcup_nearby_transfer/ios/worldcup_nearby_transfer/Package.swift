// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "worldcup_nearby_transfer",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(
            name: "worldcup-nearby-transfer",
            targets: ["worldcup_nearby_transfer"]
        )
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        // Pinned because google/nearby does not publish semantic-version tags.
        .package(
            url: "https://github.com/google/nearby.git",
            revision: "6d0ab62bb9e27cadac4a285ac46f886f293db2e1"
        )
    ],
    targets: [
        .target(
            name: "worldcup_nearby_transfer",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "NearbyConnections", package: "nearby")
            ]
        )
    ]
)
