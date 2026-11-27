// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "FlagPhoneNumber",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "FlagPhoneNumber",
            targets: ["FlagPhoneNumber", "libPhoneNumber"])
    ],
    targets: [
        .target(
            name: "libPhoneNumber",
            dependencies: [],
            path: "Sources/libPhoneNumber",
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("Internal")
            ]
        ),
        .target(
            name: "FlagPhoneNumber",
            dependencies: ["libPhoneNumber"],
            path: "Sources",
            exclude: ["Info.plist", "libPhoneNumber"],
            resources: [
                .process("Resources/FlagKit.xcassets"),
                .process("Resources/FPNCountryView.xib"),
                .copy("Resources/countryCodes.json")
            ],
            publicHeadersPath: "."
        )
    ]
)
