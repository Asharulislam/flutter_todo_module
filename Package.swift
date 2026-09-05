// swift-tools-version: 5.9
import PackageDescription

// Two variants of the same Flutter module.
//
// Flutter does NOT support AOT/release mode on the iOS Simulator, so the
// Release frameworks (no kernel_blob.bin, AOT only) fail to launch the engine
// there. Use the Debug product for simulator work and the Release product for
// physical devices and App Store builds — SPM binary targets can't switch per
// build configuration, so the consuming project picks one explicitly.
let package = Package(
    name: "FlutterTodoModule",
    platforms: [.iOS(.v16)],
    products: [
        // Physical device / shipping. AOT-compiled.
        .library(name: "FlutterTodoModule", targets: ["Flutter", "App"]),
        // Simulator / development. JIT, includes kernel_blob.bin.
        .library(name: "FlutterTodoModuleDebug", targets: ["FlutterDebug", "AppDebug"])
    ],
    targets: [
        .binaryTarget(
            name: "Flutter",
            url: "https://github.com/Asharulislam/flutter_todo_module/releases/download/ios-1.6/Flutter.xcframework.zip",
            checksum: "324fa73df3be5220017dd63689aa0e977662ada05722a3f3bf107e5b893feb97"
        ),
        .binaryTarget(
            name: "App",
            url: "https://github.com/Asharulislam/flutter_todo_module/releases/download/ios-1.6/App.xcframework.zip",
            checksum: "4ad9062a972a8da18031d2501e447b2af33031c0b2313be0a273604c3dd19d63"
        ),
        .binaryTarget(
            name: "FlutterDebug",
            url: "https://github.com/Asharulislam/flutter_todo_module/releases/download/ios-1.6/FlutterDebug.xcframework.zip",
            checksum: "f12c1df1c07da6ba9f8826927cc04cb4166b788d12323af2ac5ff6330d5cd756"
        ),
        .binaryTarget(
            name: "AppDebug",
            url: "https://github.com/Asharulislam/flutter_todo_module/releases/download/ios-1.6/AppDebug.xcframework.zip",
            checksum: "c9516a91f2e247f75918a0bc640c19974279bf8f75f4f86b328b2c83204c72c7"
        )
    ]
)
