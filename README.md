# flutter_todo

A Flutter module (`add-to-app`) that provides the Todos feature UI, embedded
into a separate native Android app. This module owns **only** the todos
screen and its networking; the native host app owns authentication (login,
signup, token storage) and hands the token to Flutter over a platform
channel.

This README documents how the two sides fit together — read it before
touching the native embedding code or the auth bridge, since the failure
modes here are easy to reintroduce.

## Project split

There are two separate codebases:

| Project | Owns | Location |
|---|---|---|
| `flutter_todo` (this repo) | Todos UI, Dio networking, DI | here |
| Native Android host app (`com.todo.myapplication`) | Login/signup, token storage (`AuthManager`), app shell (Jetpack Compose) | `/Users/macbook/Documents/android/TodoApp` — separate project, not in this repo |

The host app is a normal Android app (Compose UI, `NavHost` with
`login` / `signup` / `home` routes). From `HomeScreen`, a button launches the
Flutter module's UI as a second `Activity` inside the same process.

## How the Flutter engine is embedded

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

## Auth token flow

There is exactly one platform channel: **`com.todo.myapplication/auth`**,
method **`getToken`**, no arguments, returns `String?`.

```
AuthInterceptor (Dio)
  -> MethodChannelAuthTokenProvider.getToken()   [lib/core/network/auth_token_provider.dart]
  -> MethodChannel('com.todo.myapplication/auth').invokeMethod('getToken')
  -> MyApplication's setMethodCallHandler          (native side)
  -> AuthManager(applicationContext).getToken()    (native side, reads stored token)
  -> result.success(token)
  -> back to Dart, attached as `Authorization: Bearer <token>` header
```

Flutter never creates or refreshes the token — it only reads whatever the
native `AuthManager` currently has stored. If a request comes back
unauthenticated, check the native side's stored token before suspecting
Flutter.

### Where the token actually comes from (native side)

`AuthManager` (`com.todo.myapplication.AuthManager`, in the host app project
at `/Users/macbook/Documents/android/TodoApp`) is plain
`SharedPreferences("auth", MODE_PRIVATE)` — no encryption, no expiry
handling. `LoginScreen`/`SignUpScreen` call `AuthManager.login()` /
`.signup()`, which hit `POST api/auth/login` / `api/auth/register` via
Retrofit (`RetrofitClient`, `AuthApi.kt`) against the **same backend**
Flutter's `Dio` client talks to (`todo-backend-app-bfff.onrender.com`). On a
successful response, the returned JWT is written straight into
`SharedPreferences` under the key `"token"`. `AuthManager.logout()` just
clears the whole prefs file. `getToken()` — the method the `MethodChannel`
handler calls — is a synchronous `SharedPreferences.getString("token", null)`
read, nothing more.

### Debugging the bridge

- `MethodChannelAuthTokenProvider.getToken()` logs every call and result via
  `debugPrint('[AuthBridge] ...')` — filter Logcat on `AuthBridge` alongside
  the native `TodoHost` tag:
  ```
  adb logcat | grep -E "TodoHost|AuthBridge|MissingPlugin"
  ```
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
  formatted request/response/error boxes to the console — visible in Logcat
  under the `flutter` tag on the Android side.
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
but the auth bridge won't exist outside the native host app — the
`MethodChannel` call will throw `MissingPluginException`, which
`MethodChannelAuthTokenProvider` catches and treats as "no token" (requests
go out unauthenticated). Use `HardcodedAuthTokenProvider` if you need an
authenticated session while running standalone.

---

For general add-to-app mechanics (not specific to this project), see the
[Flutter add-to-app documentation](https://flutter.dev/to/add-to-app).
