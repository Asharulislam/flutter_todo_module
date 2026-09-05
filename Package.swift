// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FlutterTodoModule",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "FlutterTodoModule", targets: ["Flutter", "App"])
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
        )
    ]
)
