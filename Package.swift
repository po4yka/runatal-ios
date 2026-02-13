// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RunicQuotes",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "RunicQuotes",
            targets: ["RunicQuotes"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "RunicQuotes",
            dependencies: [],
            path: "RunicQuotes",
            exclude: [
                "App",
                "Resources/Fonts",
                "Resources/Assets.xcassets",
                "Resources/LaunchScreen.storyboard",
                "Resources/Localizations"
            ],
            resources: [
                .process("Resources/SeedData/quotes.json")
            ]
        ),
        .testTarget(
            name: "RunicQuotesTests",
            dependencies: ["RunicQuotes"],
            path: "RunicQuotesTests",
            exclude: [
                "Info.plist"
            ]
        )
    ]
)
