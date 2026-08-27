---
name: flutter-dev
description: >-
  Use this skill for Flutter/Dart development: project setup, flutter analyze,
  tests, hot reload, state management, building for Linux/Android, and common
  Flutter pitfalls. Activate when the project contains pubspec.yaml, lib/main.dart,
  or when the user asks to build, debug, test, or refactor a Flutter app.
---

# Flutter Development

Flutter/Dart workflows. The Flutter SDK is provided per-project via devenv (see the `devenv-direnv` skill) — run `devenv shell` (direnv) so `flutter`/`dart` resolve correctly.

## First steps in a project

- `flutter --version` to confirm the SDK is active; `flutter doctor` when something is broken (check Android toolchain, Linux toolchain, Chrome).
- Install deps: `flutter pub get` (after editing `pubspec.yaml`).
- Run the app:
  - Linux desktop: `flutter run -d linux`
  - Chrome/web (PWA work): `flutter run -d chrome`
  - Android emulator/device: `flutter devices` then `flutter run -d <id>`
- Hot reload: `r` in the running process; hot restart: `R`. Prefer hot reload for state-preserving iteration.

## Project structure (recommended)

```
lib/
  main.dart            # entry: runApp
  app/                 # MaterialApp/theme/routes
  features/<name>/     # mỗi feature: presentation/ + domain/ + data/
  core/                # widgets, utils, theme, network, storage
test/                  # widget tests
```

## Quality gates (run before finishing)

- `flutter analyze` — zero issues expected.
- `dart format lib test` — formatting (default 80 cols, 2-space indent).
- `flutter test` — widget/unit tests pass.
- `flutter build linux` (or `flutter build apk --debug` for Android) — verify it compiles.

## Testing

- Widget tests: `testWidgets('...', (tester) async { await tester.pumpWidget(MyApp()); ... })`.
- Find by `Key` (prefer `const ValueKey('...')`), not by text.
- Use `tester.pumpAndSettle()` sparingly (hangs on infinite animations — use explicit `pump(Duration)` instead).
- Mock HTTP with `http.Client` injection or `MockClient` from `package:http/testing.dart`.

## State management (choose per project)

- **Riverpod** (recommended default): `ConsumerWidget`, `ProviderScope` at root, `ref.watch`/`ref.read`; async state via `FutureProvider`/`AsyncNotifier`.
- **Bloc**: `BlocProvider` + `BlocBuilder`; events → states; keep UI dumb, logic in bloc.
- **Provider**: simple `ChangeNotifier` + `Consumer`.
- Keep business logic out of widgets; models immutable (`@immutable` classes or `freezed`).

## Serialization & codegen

- `freezed` + `json_serializable` for models:
  ```
  flutter pub add freezed_annotation json_annotation dev:freezed dev:build_runner dev:json_serializable
  dart run build_runner build --delete-conflicting-outputs
  ```
- After changing a model, re-run build_runner; commit generated `.g.dart`/`.freezed.dart` files.

## Platform builds

- Android: `flutter build apk --release` (or `--split-per-abi` for smaller APKs: arm64-v8a/armeabi-v7a/x86_64).
- Linux: `flutter build linux` — needs clang/cmake/ninja/gtk3 (in devenv `languages.c`/`packages` if missing).
- Web/PWA: `flutter build web --wasm` (experimental) or default; then serve with any static server.
- iOS/macOS builds are not available on this Linux host — note this to the user instead of attempting them.

## Debugging

- `debugPrint()` for dev logs; `print` is buffered — prefer `debugPrint`.
- Layout overflow: look for "A RenderFlex overflowed by N pixels" in console → use `Expanded`, `FittedBox`, or `ListView`/`SingleChildScrollView`.
- Unbounded height/width errors: `Column` inside `ListView`/`SingleChildScrollView` → wrap in `ConstrainedBox` or use `shrinkWrap`.
- Use DevTools: `flutter run` then press `d` / `v` to open DevTools / web debugger.

## Common pitfalls

- Missing `const` → run `dart fix --apply` (also `flutter analyze` suggests fixes).
- Stale generated code after model change → run build_runner again.
- `flutter pub get` failing offline → check `PUB_HOSTED_URL`/network; prefer committing `pubspec.lock`.
- Gradle build slow → ensure devenv provides the Android SDK/Java; check `flutter doctor --android-licenses` once.
