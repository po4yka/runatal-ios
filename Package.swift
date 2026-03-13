// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RunicQuotes",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(
            name: "RunicQuotes",
            targets: ["RunicQuotes"],
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/uber/needle.git", exact: "0.25.1"),
    ],
    targets: [
        .target(
            name: "RunicQuotes",
            dependencies: [
                .product(name: "NeedleFoundation", package: "needle"),
            ],
            path: "RunicQuotes",
            exclude: [
                "App",
                "RunicQuotes.entitlements",
                "Resources/Fonts",
                "Resources/Assets.xcassets",
                "Resources/LaunchScreen.storyboard",
                "Resources/Localizations",
            ],
            resources: [
                .process("Resources/SeedData/quotes.json"),
                .process("Resources/Translation"),
            ],
        ),
        .testTarget(
            name: "RunicQuotesTests",
            dependencies: ["RunicQuotes"],
            path: "RunicQuotesTests",
            exclude: [
                "Info.plist",
            ],
        ),
    ],
)
