// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LabRecorderiOSFeature",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "LabRecorderiOSFeature",
            targets: ["LabRecorderiOSFeature"]
        ),
    ],
    targets: [
        .binaryTarget(
            name: "lsl",
            path: "../Vendor/lsl.xcframework"
        ),
        .target(
            name: "LabRecorderiOSFeature",
            dependencies: ["lsl"]
        ),
        .testTarget(
            name: "LabRecorderiOSFeatureTests",
            dependencies: [
                "LabRecorderiOSFeature"
            ]
        ),
    ]
)
