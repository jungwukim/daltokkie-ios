// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "DalTokkieEngine",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "LunarKit", targets: ["LunarKit"]),
        .library(name: "ZiweiKit", targets: ["ZiweiKit"]),
        .library(name: "NatalKit", targets: ["NatalKit"]),
        .library(name: "SajuKit", targets: ["SajuKit"]),
    ],
    targets: [
        .target(
            name: "LunarKit",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "LunarKitTests",
            dependencies: ["LunarKit"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "ZiweiKit",
            dependencies: ["LunarKit"]
        ),
        .testTarget(
            name: "ZiweiKitTests",
            dependencies: ["ZiweiKit"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "NatalKit",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "NatalKitTests",
            dependencies: ["NatalKit"],
            resources: [.process("Resources")]
        ),
        .target(
            name: "SajuKit",
            dependencies: ["LunarKit"],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SajuKitTests",
            dependencies: ["SajuKit"],
            resources: [.process("Resources")]
        ),
    ]
)
