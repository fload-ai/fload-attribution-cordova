// swift-tools-version:5.9
import PackageDescription

// cordova-ios 8 builds this plugin as a Swift package. It rewrites the
// cordova-ios dependency line below to its own local copy, so that line keeps
// the format the Cordova docs give. The product name must be the plugin id.
let package = Package(
    name: "fload-attribution-cordova",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "fload-attribution-cordova", targets: ["fload-attribution-cordova"])
    ],
    dependencies: [
        .package(url: "https://github.com/apache/cordova-ios.git", branch: "master"),
        .package(url: "https://github.com/fload-ai/fload-attribution-ios.git", from: "1.0.2")
    ],
    targets: [
        .target(
            name: "fload-attribution-cordova",
            dependencies: [
                .product(name: "Cordova", package: "cordova-ios"),
                .product(name: "FloadAttribution", package: "fload-attribution-ios")
            ],
            path: "src/ios"
        )
    ]
)
