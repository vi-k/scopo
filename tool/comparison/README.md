# scopo next to its neighbours on pub.dev

One task — a screen needs a database and a session restored from it, both
opened and closed asynchronously — written with scopo and with packages that
solve it their own way. Every resource writes to a log, and the log shows what
happens when the screen is left during loading, re-created, or fails. The table
at the top of the package's README is read from these logs.

Each screen is written the way its package's documentation shows. The two
packages here are independent: each has its own scenarios and its own set of
neighbours.

## What is where

- `five_scenarios/` — five scenarios: leaving while the database is opening, a
  rebuild by the parent, re-creating at once, a failed session restore, and the
  closing order. Variants: scopo, scopo with `scopeKey`, cobalt_flutter,
  Riverpod with and without `ref.mounted`, get_it + watch_it, depend.
- `refresh_mid_open/` — one scenario: a refresh, that is a re-creation under a
  new key, while the database is opening, then leaving. Variants: scopo with
  `scopeKey`, Riverpod (scoped), get_it + watch_it, yx_scope.

## Running

The pinned Flutter 3.38.1 does not resolve them: Riverpod 3.4.3 needs Dart
3.12. Use a newer Flutter (3.47.0 here), not `fvm`:

```sh
cd tool/comparison/five_scenarios && flutter pub get && flutter test
cd tool/comparison/refresh_mid_open && flutter pub get && flutter test
```

Each run ends with one failing test, and that is the expected outcome: the
get_it + watch_it variant fails, and the failure is the finding — "not ready
yet" and a database nobody closes. `five_scenarios` ends at `+34 -1`,
`refresh_mid_open` at `+3 -1`.

Each is a package of its own and leaves the root's `.dart_tool` alone. The root
`flutter analyze` skips them (`analysis_options.yaml`), and `tool/` is not part
of the published package (`.pubignore`).

## scopo from the working tree

Both pin scopo to 0.21.0 from pub.dev, the version the README table describes.
To run them against the working tree instead, put a `pubspec_overrides.yaml`
(ignored by git) next to `pubspec.yaml` and run `pub get` again:

```yaml
dependency_overrides:
  scopo:
    path: ../../..
```
