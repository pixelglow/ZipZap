// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "ZipZap",
    products: [
        .library(
            name: "ZipZap",
            targets: ["ZipZap"])
    ],
    targets: [
        .target(
            name: "ZipZap",
            path: "ZipZap"
        ),
            exclude: [
                "Info.plist"
            ]
    ]
)
