// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftJXL",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftJXL",
            targets: [
                "SwiftJXL"
            ]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftJXL",
            dependencies: [
                //.target(name: "CJXL")
                .target(name: "jxl")
            ]),
        //.systemLibrary(name: "jxl", path: "/usr/local/lib")
        /*.target(
            name: "CJXL",
            linkerSettings: [.linkedLibrary("libjxl")]
        ),*/
        .binaryTarget(name: "jxl", path: "jxl.xcframework"),

    ]

)
