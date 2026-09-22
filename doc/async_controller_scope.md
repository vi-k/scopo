# AsyncControllerScope

A scope whose whole content is a controller: an object with a lifecycle of its
own, created when the scope mounts, initialized asynchronously, told to stop
when the scope leaves, and released after that. Use it when the scope exists
because something has to *run* while a part of the tree is on screen — a map
overlay driven by a bloc, a poller, a session — rather than because something
has to be *shown*.

```dart
AsyncControllerScope<PlayerController>(
  createController: (context) => PlayerController(api: ScopeModel.of<Api>(context, listen: false)),
  progressBuilder: (context) => const SizedBox.shrink(),
  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
  builder: (context, controller) => const PlayerView(),
);
```

`AsyncControllerScopeBase` is the subclassable form, and the one most
controllers end up in, since the controller usually needs things from the tree:

```dart
final class Player extends AsyncControllerScopeBase<Player, PlayerController> {
  const Player({super.key, required super.child}) : super(scopeKey: Player);

  @override
  PlayerController createController(BuildContext context) =>
      PlayerController(api: ScopeModel.of<Api>(context, listen: false));

  @override
  Widget buildOnProgress(BuildContext context) => const SizedBox.shrink();

  @override
  Widget buildOnError(BuildContext context, Object error, StackTrace stack) =>
      const SizedBox.shrink();

  @override
  Widget buildOnReady(BuildContext context, PlayerController controller) =>
      child;
}
```

`AsyncControllerScopeCore` sits under both, for a scope that needs its own
element. The family is built on the `AsyncDataScope` machinery, so everything
that topic describes — the four states, the ordered teardown, `scopeKey`, the
waiting for child scopes, the four timeouts — applies here unchanged, and the
controller is the value.

## The controller

```dart
final class PlayerController extends ScopeController {
  final Api api;

  StreamSubscription<Track>? _subscription;

  PlayerController({required this.api});

  @override
  Future<void> init() async {
    final session = await api.openSession();
    if (!mounted) return;

    _subscription = session.tracks.listen(_onTrack);
  }

  @override
  void onUnmount() => unawaited(_subscription?.cancel());

  @override
  Future<void> dispose() async => api.closeSession();
}
```

Three methods to write, and none of them has to chain to `super`:

| method | when |
| --- | --- |
| `init()` | once, asynchronously, before the ready branch is built |
| `onUnmount()` | synchronously, the moment the scope leaves the tree |
| `dispose()` | awaited, after `onUnmount`, when the scope is being taken down |

`mounted` is what to check after every `await` inside `init()`: the scope may
have gone while the initialization was suspended, and `onUnmount()` has then
already run.

The three methods the scope calls — `performInit`, `performUnmount`,
`performDispose` — are sealed. They keep `mounted`, they keep the order, and
they make each hook run at most once, so none of that rests on a controller
remembering a convention. They are public rather than hidden, so a controller
can be driven by hand in a test:

```dart
final controller = PlayerController(api: FakeApi());
await controller.performInit();
// …
await controller.performDispose();
```

The sequence goes one way. A second `performInit` does nothing, and neither
does one after `performDispose` — `init()` would otherwise run against whatever
`dispose()` has already released. There is one teardown run per controller too,
and every caller of `performDispose` observes it: a second call joins the run
that is already going instead of returning at once, and a failure the first
caller sees is a failure the second one sees as well.

## What the scope guarantees

The point of the family. A controller created by the scope is released by the
scope, on every path — including the two that are easy to get wrong when the
same thing is written by hand on top of `AsyncDataScope`, where the scope only
learns about the controller if the initialization gets as far as handing it
over:

| what happened | `onUnmount()` | `dispose()` |
| --- | --- | --- |
| the scope left before the asynchronous phase began | no controller was created | — |
| `init()` threw | yes | yes |
| the scope left while `init()` was still running | yes | yes |
| the scope left, and the ready state never arrived | yes | yes |
| the ordinary path: ready, then gone | yes | yes |

`onUnmount()` is the synchronous half and always runs first — at the moment the
scope leaves the tree, not when the asynchronous teardown gets around to it.
That is the difference that matters for a controller driving something outside
itself: it stops reaching the outside world at once, whatever the rest of the
teardown is still waiting for.

A controller that hangs cannot hold anything hostage: the wait for a cancelled
initialization is bounded by `initCancellationTimeout` and the wait for
`dispose()` by `disposeScopeTimeout` — see the `debug` topic.

## Reading the controller from the subtree

```dart
final controller = AsyncControllerScope.of<PlayerController>(
  context,
  listen: false,
).controller;
```

`of`, `maybeOf` and `select` return an `AsyncControllerScopeContext`:
`controller` throws before the controller is ready, `controllerOrNull` returns
`null`, and `hasController` is the question on its own. Widgets under `builder`
are below a ready scope and can use `controller`. The three answers of
`AsyncDataScopeContext` — `data`, `dataOrNull`, `hasData` — are inherited and
still work; they are the same object under the name the value had before this
family gave it its own.

The subclassable form has the same three as statics, taking the widget type
first:

```dart
final position = AsyncControllerScopeBase.select<Player, PlayerController, int>(
  context,
  (scope) => scope.controller.position,
);
```

## Following what the controller hears

The scope notifies its dependents when its own state changes — waiting, ready,
error — and for most scopes that happens once. A controller that is running has
more to say while it runs: the track the session pushed, the position it
reached. Carrying that to the widgets is the subtree's business rather than the
scope's, and the stream the controller opened is the obvious road. Say
`PlayerController` hands the session's stream out as `tracks`:

```dart
@override
Widget buildOnReady(BuildContext context, PlayerController controller) =>
    StreamBuilder<Track>(
      stream: controller.tracks,
      builder: (context, snapshot) => TrackTitle(title: snapshot.data?.title),
    );
```

Three things come with it.

**Every event rebuilds the whole branch.** Two tracks with the same title and a
different position rebuild `TrackTitle` twice, and the title is all it reads.

**An error empties the snapshot.** The builder is handed an `AsyncSnapshot`
made by `withError`, and that one carries no data: a widget that was showing a
title shows `null` from the session's first complaint onwards, while the track
it was showing is still the one playing.

**The stream has one listener.** A second widget that wants the same track gets
`Bad state: Stream has already been listened to`, so either the stream becomes
broadcast or the value is carried down by hand.

The value already lives in the controller — the subscription is its own. Let it
keep what it hears and say when that changed:

```dart
final class PlayerController extends ScopeController with ChangeNotifier {
  final Api api;

  StreamSubscription<Track>? _subscription;
  Track? _track;

  PlayerController({required this.api});

  static V select<V>(
    BuildContext context,
    V Function(PlayerController controller) selector,
  ) =>
      ScopeNotifier.select<PlayerController, V>(context, selector);

  String get title => _track?.title ?? '';

  int get position => _track?.position ?? 0;

  @override
  Future<void> init() async {
    final session = await api.openSession();
    if (!mounted) return;

    _subscription = session.tracks.listen((track) {
      _track = track;
      notifyListeners();
    });
  }

  @override
  void onUnmount() => unawaited(_subscription?.cancel());

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    await api.closeSession();
    super.dispose();
  }
}
```

`ScopeNotifier.value` puts that controller in front of the subtree, and it is
the whole bridge:

```dart
@override
Widget buildOnReady(BuildContext context, PlayerController controller) =>
    ScopeNotifier<PlayerController>.value(
      value: controller,
      builder: (context) => const PlayerView(),
    );
```

The `select` on the controller is the accessor of this pair, and the reason to
write it is that it names the bridge once. A widget below asks the controller
for the one value it shows:

```dart
final title = PlayerController.select(
  context,
  (controller) => controller.title,
);
```

and is rebuilt when the title changes and not when the position does.

`ScopeNotifier.of` and `maybeOf` with `listen: true` are the other end of that
scale: they rebuild on every `notifyListeners`, which is what the
`StreamBuilder` above was doing.

Two things about the teardown are worth reading twice.

`dispose()` is the controller's hook *and* `ChangeNotifier`'s method — the
mixin sits on top of `ScopeController`, so the two are one member. That is why
the override ends with `super.dispose()`: without it the listeners are never
let go of, and Flutter's leak tracker says so in the first test that watches.

The subscription is cancelled in both halves on purpose. `onUnmount()` stops
the events from reaching a scope that is on its way out, at the moment it
leaves; `dispose()` awaits the cancellation before closing the session behind
it. The second one is what a `StreamBuilder` has no way to ask for — it cancels
from `State.dispose` and lets the returned future go.

## What this family does not do

**It does not make the controller observable.** The scope notifies its
dependents when its *state* changes — waiting, ready, error — and not when
something inside the controller changes. The section above is the way to do
that: a controller that is a `Listenable`, with a `ScopeNotifier.value` under
this scope.

**It reports no progress.** `init()` is a `Future<void>`, so there is nothing
between "initializing" and "ready" to show. An initialization that has stages
worth naming belongs in `AsyncDataScope`, whose context reports them.

**It does nothing with a failed initialization** beyond what every family does:
the error reaches `buildOnError`, which is required precisely so that the
decision is made rather than defaulted. Route it onward from there, or assign a
`ScopeObserver` — the `debug` topic has both.

## Where next

| topic | what for |
| --- | --- |
| `AsyncDataScope` | the machinery underneath: states, teardown order, `scopeKey` |
| `AsyncScope` | the same lifecycle with no value at all |
| `ScopeNotifier` | making the controller itself observable |
| `debug` | the four timeouts and the observer |
