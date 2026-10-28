# quickstart

One screen owns one local resource through `AsyncDataScope`. It shows loading
and readiness; **Recreate scope** replaces the widget while keeping the same
`scopeKey`. The console prints `closed 1` before `opening 2`: the old
resource's asynchronous release finishes before the new acquisition starts.
Each delay is 300 ms, within the scope's default three-second waiting limits.

From the repository root, using Flutter 3.38.1 through fvm:

```sh
cd example/quickstart
fvm flutter pub get
fvm flutter test
```

To run in Chrome, generate platform files locally, then start the app:

```sh
fvm flutter create --empty --platforms=web .
fvm flutter run -d chrome
```

`--empty` keeps `flutter create` from adding its sample test, which does not
compile against this app. Platform files are omitted from this example.
`lib/main.dart` contains the whole app; no plugins or external services are
needed. For the full `Scope` with a dependency container and state, see
[minimal](../minimal).
