# flutter_todo

A Flutter module (`add-to-app`) that provides the Todos feature UI, embedded
into separate native **Android and iOS** host apps. This module owns **only**
the todos screen and its networking; each host app owns authentication
(login, signup, token storage) and hands the token to Flutter over a platform
channel.

This README documents how the pieces fit together — read it before touching
the native embedding code or the auth bridge, since the failure modes here
are easy to reintroduce.

## Project split

Three separate codebases:

| Project | Owns | Location |
|---|---|---|
| `flutter_todo` (this repo) | Todos UI, Dio networking, DI | here |
| Android host (`com.todo.myapplication`) | Login/signup, token storage (`AuthManager` → SharedPreferences), Compose app shell | `/Users/macbook/Documents/android/TodoApp` |
| iOS host (`com.todo.myapplication`) | Login/signup, token storage (`KeychainStore`), SwiftUI app shell | `/Users/macbook/Documents/android/todoIOS` |

Both hosts follow the same shape: a native auth flow, then a button that
opens the Flutter module's UI on a pre-warmed engine. Both talk to the same
backend and the same platform channel, so **the Dart code is identical for
both — no platform branching anywhere in `lib/`.**

## Android — build-time wiring (Gradle)

This project does **not** use the "textbook" add-to-app setup where the host
app's `settings.gradle` source-includes this module's local `.android`
directory (`include ':flutter'` pointed at a relative path). Instead, this
module is built as a standalone **AAR and published to a private Maven repo
(GitHub Packages)**, and the host app just depends on it like any ordinary
third-party library. That fully decouples the two builds — the host app
never needs Flutter tooling installed to build.

**`flutter_todo/build.gradle`** (this repo, root — not the auto-generated
`.android/**` Gradle files) applies `maven-publish` and declares the
publication:

```gradle
plugins { id 'maven-publish' }

publishing {
    publications {
        release(MavenPublication) {
            groupId = 'com.example.flutter_todo'
            artifactId = 'flutter_release'
            version = '1.6'
            artifact("build/host/outputs/repo/com/example/flutter_todo/flutter_release/1.0/flutter_release-1.0.aar")
            pom.withXml { /* adds io.flutter engine artifacts as POM dependencies */ }
        }
    }
    repositories {
        maven {
            name = "GitHubPackages"
            url = uri("https://maven.pkg.github.com/Asharulislam/flutter_todo_module")
            credentials {
                username = project.findProperty("gpr.user")
                password = project.findProperty("gpr.key")
            }
        }
    }
}
```

Note the `artifact(...)` path is hardcoded to `.../1.0/flutter_release-1.0.aar`
— that's not a stale version number, that's just the fixed local filename
`flutter build aar` always produces regardless of what version you publish
under. The `version = '1.6'` field is what consumers actually see; it's
fully decoupled from that local build output name.

**`TodoApp/settings.gradle.kts`** (host app, at
`/Users/macbook/Documents/android/TodoApp`) adds two extra Maven repos on
top of `google()`/`mavenCentral()`:

```kotlin
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
        maven {
            url = uri("https://maven.pkg.github.com/Asharulislam/flutter_todo_module")
            credentials {
                username = providers.gradleProperty("gpr.user").get()
                password = providers.gradleProperty("gpr.key").get()
            }
        }
    }
}
```

- `download.flutter.io` resolves the `io.flutter:flutter_embedding_release`
  and per-ABI engine artifacts that this module's published POM depends on.
- The GitHub Packages repo is where the module's own AAR was published to.

`gpr.user` / `gpr.key` (a GitHub PAT with `read:packages` / `write:packages`
scope) live in `~/.gradle/gradle.properties` **globally on the machine**,
not committed in either project — keep it that way.

**`TodoApp/app/build.gradle.kts`** then consumes the module exactly like any
other library:

```kotlin
debugImplementation("com.example.flutter_todo:flutter_release:1.6")
releaseImplementation("com.example.flutter_todo:flutter_release:1.6")
```

### Publishing a new Android version

Whenever `flutter_todo` changes and the host app needs to pick it up:

1. `flutter build aar` — builds the AAR locally (in `flutter_todo/`).
2. Bump `version` in `flutter_todo/build.gradle` (e.g. `1.6` → `1.7`).
3. `./gradlew publish` (from `flutter_todo/`) — pushes it to GitHub Packages
   under the new version. Requires `gpr.user`/`gpr.key` to be set.
4. Bump both `implementation(...)` version strings in
   `TodoApp/app/build.gradle.kts` to match.
5. Sync and rebuild the host app.

There is no "hot reload" across this boundary — every Dart change requires
this full publish-and-bump cycle before the host app sees it.

## Android — engine embedding

Add-to-app needs a `FlutterEngine` warmed up *before* the user taps into
Flutter, otherwise the first screen shows a blank frame while the engine
boots. The host app does this in `MyApplication.onCreate()`:

```kotlin
class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        val flutterEngine = FlutterEngine(this)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.todo.myapplication/auth"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getToken" -> result.success(AuthManager(applicationContext).getToken())
                else -> result.notImplemented()
            }
        }

        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )

        FlutterEngineCache.getInstance().put("my_engine", flutterEngine)
    }
}
```

Note the order: the `MethodChannel` handler is registered **before**
`executeDartEntrypoint` starts running Dart's `main()`. That matters because
`executeDartEntrypoint` kicks off Dart execution essentially concurrently
with the rest of `onCreate()` — registering the handler first closes off a
startup race where an early `getToken()` call could otherwise fire before
anything is listening.

The engine is cached under the key **`"my_engine"`** for the whole app
lifetime. `HomeScreen` then reuses that exact instance instead of spinning
up a new one:

```kotlin
context.startActivity(
    FlutterActivity.withCachedEngine("my_engine").build(context)
)
```

**This pairing is load-bearing.** If any entry point into the Flutter UI
uses `FlutterActivity.createDefaultIntent(context)` instead of
`withCachedEngine("my_engine")`, Android creates a fresh `FlutterEngine`
that never had the `MethodChannel` handler registered on it — every call
from Dart to `getToken` then fails with:

```
MissingPluginException(No implementation found for method getToken on channel com.todo.myapplication/auth)
```

This happened once already (`HomeScreen` originally used
`createDefaultIntent`) — if you add a second way to open the Flutter screen,
make sure it also goes through `withCachedEngine("my_engine")`.

## iOS — build-time wiring (SPM)

Same philosophy as Android (published artifact, not a local path), different
plumbing. GitHub Packages has no Swift/CocoaPods package type, so the
xcframeworks are attached to a **GitHub Release** and consumed as SPM binary
targets.

`Package.swift` lives at this repo's root and vends **two products**:

```swift
products: [
    // Physical device / shipping. AOT-compiled.
    .library(name: "FlutterTodoModule", targets: ["Flutter", "App"]),
    // Simulator / development. JIT, includes kernel_blob.bin.
    .library(name: "FlutterTodoModuleDebug", targets: ["FlutterDebug", "AppDebug"])
]
```

**Why two products — this is the big iOS gotcha.** Flutter does **not**
support AOT/release mode on the iOS Simulator. The Release xcframeworks
contain no `kernel_blob.bin`, so on a simulator the engine simply refuses to
start, in *any* Xcode build configuration, with:

```
[ERROR:flutter/shell/common/engine.cc(219)] Engine run configuration was invalid.
[ERROR:flutter/shell/common/shell.cc(799)] Could not launch engine with configuration.
```

Note the host app does **not** crash when this happens — it keeps running
with a dead engine. "The app didn't crash" is not evidence the engine
started; grep the log for `Could not launch engine` instead.

SPM binary targets can't switch per build configuration (CocoaPods can —
that's its one real advantage here), so the consuming project picks a product
explicitly. `todoIOS/project.yml`:

```yaml
packages:
  FlutterTodoModule:
    url: https://github.com/Asharulislam/flutter_todo_module
    branch: main

targets:
  todoIOS:
    dependencies:
      # Debug product = JIT frameworks, required for the iOS Simulator.
      # Switch to product: FlutterTodoModule for physical devices / App Store.
      - package: FlutterTodoModule
        product: FlutterTodoModuleDebug
```

`branch: main` rather than a version, because the release tag (`ios-1.6`)
isn't valid semver and SPM can't resolve it as a version.

### Publishing a new iOS version

1. `flutter build ios-framework` in `flutter_todo/`.
2. From `build/ios/framework/Release/`, zip `Flutter.xcframework` and
   `App.xcframework`.
3. From `build/ios/framework/Debug/`, **copy** the two xcframeworks to
   `FlutterDebug.xcframework` / `AppDebug.xcframework` before zipping — SPM
   requires the `.xcframework` inside the zip to match the binary target
   name, and both variants would otherwise be called `Flutter`/`App`.
4. `swift package compute-checksum <each zip>` — four checksums.
5. `gh release create ios-1.7 *.zip --repo Asharulislam/flutter_todo_module`
   (or `gh release upload` to an existing tag).
6. Update all four URLs + checksums in `Package.swift`, commit, push.
7. In `todoIOS/`: delete
   `todoIOS.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`,
   then `xcodegen generate`.

Step 7 is not optional. SPM pins to a **commit**, so without clearing
`Package.resolved` Xcode keeps resolving the old one and reports a
misleading `Missing package product 'FlutterTodoModuleDebug'`. In the Xcode
UI the equivalent is File → Packages → Reset Package Caches, and quitting
Xcode entirely if xcodegen rewrote the project while it was open.

## iOS — engine embedding

The iOS host is SwiftUI, so the engine is warmed up in an `AppDelegate`
bridged in via `@UIApplicationDelegateAdaptor`
(`todoIOS/todoIOS/FlutterBridge.swift`):

```swift
enum FlutterHost {
    static let engine = FlutterEngine(name: "my_engine")
}

class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FlutterHost.engine.run()

        FlutterMethodChannel(
            name: "com.todo.myapplication/auth",
            binaryMessenger: FlutterHost.engine.binaryMessenger
        ).setMethodCallHandler { call, result in
            guard call.method == "getToken" else {
                result(FlutterMethodNotImplemented); return
            }
            result(KeychainStore.get("token"))
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

Two things here are non-obvious and were both learned the hard way:

**1. `run()` must come BEFORE `setMethodCallHandler` — the opposite of
Android.** `FlutterEngine` asserts otherwise and hard-crashes with
`'Setting a message handler before the FlutterEngine has been run.'` On
Android the handler goes first (to close a startup race); on iOS that order
is illegal.

**2. Never reach the engine through the app delegate.** The obvious-looking
`UIApplication.shared.delegate as? AppDelegate` returns **nil** in Xcode
debug builds, where app code loads from `todoIOS.debug.dylib` next to a
`__preview.dylib` and the same Swift class can end up with two distinct type
identities. The cast fails on an object that genuinely *is* an `AppDelegate`.
That's why the engine lives in the `FlutterHost` static instead — it's also a
closer analogue of Android's `FlutterEngineCache`.

Presenting the Flutter UI from SwiftUI needs a `UIViewControllerRepresentable`
wrapper, since `FlutterViewController` is UIKit:

```swift
struct FlutterTodosView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> FlutterViewController {
        FlutterViewController(engine: FlutterHost.engine, nibName: nil, bundle: nil)
    }
    func updateUIViewController(_ uiViewController: FlutterViewController, context: Context) {}
}
```

`HomeScreen` then presents it with
`.fullScreenCover(isPresented: $showTodos) { FlutterTodosView().ignoresSafeArea() }`
— the SwiftUI counterpart of Android's `startActivity(...)`.

## Auth token flow

There is exactly one platform channel: **`com.todo.myapplication/auth`**,
method **`getToken`**, no arguments, returns `String?`.

```
AuthInterceptor (Dio)
  -> MethodChannelAuthTokenProvider.getToken()   [lib/core/network/auth_token_provider.dart]
  -> MethodChannel('com.todo.myapplication/auth').invokeMethod('getToken')
  -> native handler                              (MyApplication.kt / FlutterBridge.swift)
  -> SharedPreferences "token"  /  Keychain "token"
  -> result.success(token) / result(token)
  -> back to Dart, attached as `Authorization: Bearer <token>` header
```

The Dart half is platform-agnostic — the same `MethodChannel` call is served
by Kotlin on Android and Swift on iOS. Flutter never creates or refreshes the
token; it only reads what the native side has stored. If a request comes back
unauthenticated, check the native store before suspecting Flutter.

### Where the token actually comes from

**Android** — `AuthManager` (`com.todo.myapplication.AuthManager`, in
`/Users/macbook/Documents/android/TodoApp`) is plain
`SharedPreferences("auth", MODE_PRIVATE)` — no encryption, no expiry
handling. `LoginScreen`/`SignUpScreen` call `AuthManager.login()` /
`.signup()`, which hit `POST api/auth/login` / `api/auth/register` via
Retrofit (`RetrofitClient`, `AuthApi.kt`). On success the returned JWT is
written to `SharedPreferences` under `"token"`; `logout()` clears the prefs
file. `getToken()` is a synchronous
`SharedPreferences.getString("token", null)`, nothing more.

**iOS** — `KeychainStore` (`todoIOS/todoIOS/KeychainStore.swift`) wraps
`kSecClassGenericPassword` under service `com.todo.myapplication.auth`.
`AuthManager` (`@MainActor`, `ObservableObject`) calls the same two endpoints
via `URLSession` (`Network/AuthApi.swift`) and stores the JWT under the same
`"token"` key. Note the channel handler reads `KeychainStore` **directly**
rather than going through `AuthManager`, which is `@MainActor`-isolated.

Both hit the same backend Flutter's `Dio` client uses
(`todo-backend-app-bfff.onrender.com`). Neither side checks JWT expiry.

### Debugging the bridge

- `MethodChannelAuthTokenProvider.getToken()` logs every call and result via
  `debugPrint('[AuthBridge] ...')`; the native handlers log `[TodoHost]`.

  Android:
  ```
  adb logcat | grep -E "TodoHost|AuthBridge|MissingPlugin"
  ```
  iOS (simulator):
  ```
  xcrun simctl spawn booted log stream --predicate 'processImagePath CONTAINS "todoIOS"' \
    | grep -iE "TodoHost|AuthBridge|flutter:"
  ```
  A healthy round trip looks like `[TodoHost] getToken called, returning: eyJ...`
  followed by `[AuthBridge] getToken() -> 137 chars`.
- To isolate whether a bug is in the bridge or in the backend, swap the DI
  registration in `lib/di/injection_container.dart` from
  `MethodChannelAuthTokenProvider.new` to `HardcodedAuthTokenProvider.new`
  (already defined in `auth_token_provider.dart`, holds a fixed test JWT).
  If requests succeed with the hardcoded token but not the bridge, the
  problem is native-side (engine mismatch, or `AuthManager` returning
  nothing). **Always revert this before shipping** — it bypasses real auth
  entirely.

## Networking

`lib/core/network/dio_client.dart` builds one shared `Dio` instance:

- Base URL / timeouts come from `lib/core/constants/api_constants.dart`
  (`ApiConstants.baseUrl`, overridable via `--dart-define=API_BASE_URL=...`).
- `AuthInterceptor` (`api_interceptors.dart`) attaches the bearer token to
  every request via the token provider above.
- `PrettyDioLogger` is attached in debug builds only (`kDebugMode`), printing
  formatted request/response/error boxes to the console — under the `flutter`
  tag in Logcat on Android, and as `flutter:` lines in the Xcode console / the
  `simctl log stream` command above on iOS.
- `TodoRemoteDataSourceImpl._mapDioException` translates `DioException` into
  typed `ServerException` / `NetworkException`, falling back to
  `error.error?.toString()` when Dio's own `message` is null (which happens
  for `DioExceptionType.unknown` — Dio's catch-all wraps the real thrown
  object into `.error` without populating `.message`).

## Dependency injection

`lib/di/injection_container.dart` wires everything via `get_it`. Call
`initDependencies()` once in `main()` before `runApp()`. The only thing that
should ever change here day-to-day is swapping the `AuthTokenProvider`
implementation for debugging (see above).

## Running / testing this module standalone

This module can still be run on its own (`flutter run`) for UI iteration,
but the auth bridge won't exist outside a native host app — the
`MethodChannel` call will throw `MissingPluginException`, which
`MethodChannelAuthTokenProvider` catches and treats as "no token" (requests
go out unauthenticated). Use `HardcodedAuthTokenProvider` if you need an
authenticated session while running standalone.

This is also the *fast* way to iterate on Dart. There is no hot reload across
the add-to-app boundary on either platform — every Dart change otherwise
requires a full publish-and-bump cycle (AAR + version bump on Android, or
re-zip + re-checksum + new release on iOS) before a host app sees it. Do the
Dart work standalone, publish once when it's done.

---

For general add-to-app mechanics (not specific to this project), see the
[Flutter add-to-app documentation](https://flutter.dev/to/add-to-app).
