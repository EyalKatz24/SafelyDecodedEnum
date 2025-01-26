// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "SafelyDecodedEnum",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SafelyDecodedEnum",
            targets: ["SafelyDecodedEnum"]
        ),
        .executable(
            name: "SafelyDecodedEnumClient",
            targets: ["SafelyDecodedEnumClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "509.0.0"..<"601.0.0-prerelease")
    ],
    targets: [
        .macro(
            name: "SafelyDecodedEnumMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),

        .target(name: "SafelyDecodedEnum", dependencies: ["SafelyDecodedEnumMacros"]),

        .executableTarget(name: "SafelyDecodedEnumClient", dependencies: ["SafelyDecodedEnum"]),

        .testTarget(
            name: "SafelyDecodedEnumTests",
            dependencies: [
                "SafelyDecodedEnumMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
