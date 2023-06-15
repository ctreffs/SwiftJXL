// swift-tools-version: 5.5
import PackageDescription

let package = Package(
    name: "SwiftJXL",
    platforms: [
        .macOS(.v12),
        .iOS(.v14),
    ],
    products: [
        .library(name: "SwiftJXL", targets: ["SwiftJXL"]),
    ],
    targets: [
        .target(name: "SwiftJXL", dependencies: ["jxl"]),
        .binaryTarget(name: "jxl", path: "jxl.xcframework"),
        .executableTarget(name: "JXLCoder", dependencies: ["SwiftJXL"]),
    ]
)
