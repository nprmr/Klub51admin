// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Klub51",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
    ],
    products: [
        .library(
            name: "Klub51Core",
            targets: ["Klub51Core"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    ],
    targets: [
        .target(
            name: "Klub51Core",
            dependencies: ["KeychainAccess"],
            path: "Sources"
        ),
    ]
)
