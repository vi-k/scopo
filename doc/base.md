# base

Every scope family of this package — `ScopeWidgetBase`, `ScopeModel`,
`ScopeNotifier`, `AsyncScope`, `AsyncDataScope`, `AsyncControllerScope`,
`LiteScope` and `Scope` — stands on the same three types. Together they say
what a scope is to the widget tree: an `InheritedWidget` that can be found from
below, an element that owns whatever the scope holds, and one lookup protocol
shared by all of them.

| type | what it is |
| --- | --- |
| `ScopeInheritedWidget` | the `InheritedWidget` every scope widget descends from |
| `ScopeContext` | the lookup protocol: `of`, `maybeOf`, `select` |
| `ScopeInheritedElement` | what the element of a scope has to provide |

An application never instantiates them. The layer is still worth reading twice
over: it is where the difference between `of`, `select` and `listen: false` is
decided — identically in every family — and it is the contract to implement
when writing a scope of your own.

## The widget

```dart
abstract base class ScopeInheritedWidget extends InheritedWidget {
  final Object? tag;

  const ScopeInheritedWidget({super.key, this.tag, super.child});
}
```

`tag` names one particular scope. Two scopes of the same type are otherwise
indistinguishable in the output, where an untagged scope appears as
`CounterScope(#4e0b7)` and a tagged one as `CounterScope(cart)` — see the
`debug` topic for the format. Every family forwards a `tag` parameter to this
constructor, so any scope can be tagged.

The `child` needs a word of warning, because it is not what a scope displays. A
plain `InheritedWidget` wraps a subtree passed to it; a scope builds its own
through `buildChild()`, which is where the waiting, initializing, error and
closing branches of the richer families come from. The constructor still
accepts a `child`, so a family that wants the plain behaviour can pass one and
use it from `buildChild()`; nothing in the package does. The default is a
placeholder that refuses to create an element at all — if a scope ever builds
that `child` instead of its own, the failure is immediate rather than subtle.

## The element

```dart
abstract interface class ScopeInheritedElement<W extends ScopeInheritedWidget>
    implements ScopeContext<W> {
  W get widget;

  @mustCallSuper
  void init();

  @mustCallSuper
  void dispose();

  Widget buildChild();
}
```

`init()` runs once, after the element is mounted and before its first
`buildChild`. If it throws, that is the end of the scope: the hook is not
attempted again, the scope shows an error instead of its subtree, and every
later build reports the same failure. `dispose()` runs when the element is
unmounted, and it runs after a failed `init()` too — an attempt that gave up
halfway may already hold something, and this is where it is given back, so a
family disposer has to expect a partially initialized scope. Both are
`@mustCallSuper`: a family that overrides them extends the lifecycle rather
than replacing it. The mounted element is connected to its ancestors, so an
`init()` hook may look one up with `listen: false`; subscribing from the hook
is not supported and an assertion says so. Everything a scope owns — a model, a
notifier subscription, a dependency container, a place in the queue of a
`scopeKey` — is acquired in the first and released in the second.

The element is also the `ScopeContext` of its own scope: what a descendant
receives from `of` is this object, which is why `select` can read the current
value straight from it.

The bookkeeping behind all of that — the per-dependent subscriptions, the
rebuild that only notifies instead of rebuilding the subtree — lives in
`ScopeWidgetElementBase`, described in the `ScopeWidget` topic. Implementing
`ScopeInheritedElement` from scratch is not the intended path; extending that
class is.

## Finding a scope

Three entry points, all static on `ScopeContext`, where `W` is the widget type
and `C` is the context type of the family:

```dart
ScopeContext.maybeOf<W, C>(context, listen: false); // C?, null if not found
ScopeContext.of<W, C>(context, listen: false);      // C, throws if not found
ScopeContext.select<W, C, V>(context, selector);    // V, throws if not found
```

In practice these are called through the wrapper each family exposes, so that
the type arguments stay short and correct:

```dart
final config = ScopeWidgetBase.of<ApiConfig>(context, listen: false);
final apiKey = ScopeWidgetBase.select<ApiConfig, String>(
  context,
  (widget) => widget.apiKey,
);
```

The search itself is `getElementForInheritedWidgetOfExactType<W>()`: ancestors
only, and the **exact** type — a scope declared as
`class CartScope extends ShopScope` is not found by asking for `ShopScope`.
Looking a scope up never rebuilds anything by itself; what a caller subscribes
to is decided by the argument below.

## listen, and what it costs

`listen: false` looks the scope up and subscribes to nothing. The caller is
never rebuilt because of that scope. This is what code outside `build` wants —
a button handler reaching for a service, a callback reading the current state
once:

```dart
onPressed: () => ScopeModel.of<Cart>(context, listen: false).clear(),
```

`listen: true` subscribes to **every** change of that scope. The dependent is
rebuilt whenever the scope notifies, whether or not anything it reads has
changed.

`select` subscribes to one value and is the reason a scope can serve a large
subtree cheaply. It has no `listen` parameter — selecting is listening — and no
`maybe` variant: a missing scope is an error rather than a null.

## What select actually does

```dart
final userName = ScopeModel.select<Session, String>(
  context,
  (session) => session.userName,
);
```

The selector runs immediately, and the pair `(value, selector)` is stored as
the dependent's subscription. When the scope later notifies, every stored pair
of every dependent is re-evaluated: the dependent is rebuilt only if
`selector(scope) != value` for at least one of them. A widget that selected
`userName` sleeps through a change of `cartTotal`.

Five consequences are worth keeping in mind.

**The comparison is `!=`,** so the `==` of the selected value decides
everything. Select a field, a record or an immutable value. A selector that
builds a fresh `List` or a new object on every call compares unequal every
time, and the widget rebuilds as if it had never selected at all.

**Selectors accumulate.** Several `select` calls in one `build` create several
subscriptions, and a change in any of them rebuilds the widget once. Reading
three fields of a model is three selects, not one selector returning three
values in a list — see above for why the list would be worse.

**`of(..., listen: true)` wins over any `select` in the same build.** It
subscribes to everything, and a subscription to everything cannot be narrowed
by adding a selector to it — in either order, the widget ends up rebuilt on
every notification. Use one or the other for a given scope in a given `build`.

**The captured value is refreshed on every build.** Subscriptions are
re-established while the dependent builds, as they are anywhere in Flutter, so
the pair a scope compares against is the one from the dependent's latest build,
not from its first.

**A subscription may only be taken from a build**, and an assertion says so —
a `FlutterError` whose summary is that one line, with the explanation and the
advice under it and the offending dependent named at the bottom, the way the
framework reports a mistimed lookup of its own. What a dependent asked for is
remembered per build, and the boundary between one build and the next is taken
from the frame — Flutter offers no hook for "this dependent is about to build".
A registration made outside a build therefore belongs to whichever build shares
its frame, and is dropped by the first build that does not:
`didChangeDependencies` runs in the same frame as the build after it, so a
`select` there looks like it works and then disappears on the first rebuild
that comes from the parent rather than from a change. To react to a change
rather than to show it, keep the subscription in `build` and
look the scope up with `listen: false` from `didChangeDependencies`.

**A builder counts as a build too**, and not only the one a `LayoutBuilder`
runs: `OrientationBuilder`, `SliverLayoutBuilder` and the item builders of the
lazy lists all build a subtree on behalf of the element that called them, and
what a `select` there registers belongs to that element. Where the call comes
from varies — a layout callback on one frame, the element's own rebuild on the
next — and neither of those is what Flutter calls a build, so the line is drawn
around the dependent instead: what the assertion refuses is a subscription
taken while the framework is rebuilding that very dependent, outside its
`build`. That is `didChangeDependencies`, under a layout callback or anywhere
else. The one shape left uncaught is a `didUpdateWidget` of a widget that is
itself under a layout callback.

**None of this is checked in a release build.** `debugDoingBuild`,
`BuildOwner.debugBuilding` and `RenderObject.debugActiveLayout` are all set
inside assertions of Flutter's own, so a release build has no way to tell a
build from a timer callback — and the assertion is not compiled into it either.
The mistake is silent there: the subscription disappears at one of the later
rebuilds, and the widget stops hearing about the value it selected.

## Where Flutter's own dependencies differ

**A plain `InheritedWidget` has no such rule**, and
`State.didChangeDependencies` is documented as a safe place to call
`dependOnInheritedWidgetOfExactType` from. It can be, because the dependency it
takes is membership and nothing else: the dependent is in the set or it is not,
and the set is emptied only when the element is deactivated. There is no
per-build boundary to fall outside of, so when the call is made does not
matter.

What a scope stores is not membership but a pair `(value, selector)`, and a
pair is only true of the build that made it. It has to be replaced build by
build, and whatever replaces it has to know which build it belongs to — which
is the whole of the rule above.

**`InheritedModel` is the closest thing Flutter has to a selector, and it keeps
its aspects forever.** `InheritedModelElement.updateDependencies` adds the new
aspect to the ones the dependent already had, and nothing takes any of them
away until the element leaves the tree. A widget that asked for `a` in one
build and for `b` in the next is woken by both from then on, including for the
branch it no longer takes; one call with `aspect: null` marks it as depending
on everything, permanently, whatever it selects afterwards. The accumulation is
silent — the dependent is simply rebuilt more often than it needs to be, and
more often the longer it lives — which is why the timing of the call is not
worth an assertion there: nothing about it fails outright.

A scope empties what a dependent asked for at the start of each of that
dependent's builds, so what wakes it is what its latest build actually
selected. That reset is what the rule above pays for: a registration has to
say which build it belongs to, and one made from `didChangeDependencies` has
no answer.

## Depending on itself

A scope element may subscribe to its own scope — that is how the richer
families rebuild their own subtree as the initialization advances.
`InheritedElement` forbids it (an assert in `notifyClients` blocks a self
dependency), so those subscriptions are kept apart from the rest and notified
separately. The mechanism belongs to `ScopeWidgetElementBase`; it matters here
only as the reason `ScopeInheritedElement` is an interface a family implements
rather than a mixin an application applies.

## Errors

Both failures are plain exceptions carrying the type that was asked for:

```text
Exception: CounterScope not found in the context
```

`of` and `select` did not find the widget above the context. Either the scope
is genuinely not there, or the context belongs to a widget above it rather than
below — the usual mistake being a lookup from the very `build` that installs
the scope. `maybeOf` returns `null` in the same situation and is the right call
when absence is expected.

A lookup with `listen: true` that found nothing is still remembered as a
dependency, exactly as Flutter's own `dependOnInheritedWidgetOfExactType` would
remember it. A widget that asked when there was no scope above it and is later
carried under one — by a `GlobalKey` — is therefore told its dependencies have
changed and asks again.

```text
Exception: The element of ScopeModel<Counter> is not ScopeModelContext<ScopeModel<Counter>, Counter>
```

The widget was found, but its element is not the context type the call asked
for. This is a mismatch of type arguments — a family's accessor used against a
scope of a different family.

## Accessors and editor templates

Every family finds its scope through statics that take the family's type
arguments —
`Scope.select<App, AppDependencies, AppState, V>(context, selector)` and its
four neighbours. Written out as wrappers on the scope, that is the triple
repeated five times per scope.

Each family also ships an accessor object that takes those arguments once:

```dart
final class App extends Scope<App, AppDependencies, AppState> {
  static const access = ScopeAccess<App, AppDependencies, AppState>();
}

final counter = App.access.select(context, (state) => state.counter);
```

It is a forwarder and nothing more — every method is the static of the same
name — so the two are interchangeable, and a scope that wants accessors under
its own names still writes them. The `README` of the package has the table of
all eight.

A template answers the same cost the other way round. Its skeletons write the
accessors out as statics of the scope — `App.select(context, …)` at every call
site, with nothing to type, because the template typed them. The two are not
rivals: one is for code written by hand, the other for code written by a key
stroke. They ship with the package: `ide/scopo.code-snippets` for VS Code (and
Cursor, Windsurf, Antigravity) and `ide/scopo-live-templates.xml` for IntelliJ
and Android Studio, both in the package directory alongside `lib/`. Eleven
templates — one per family, two for a dependency container (automatic and
hand-written), one for the accessor line. Each writes out every class the shape
needs, in one paste, for you to split across files as you like:

```json
"scopo: The accessor object": {
  "scope": "dart",
  "prefix": "scopo-access",
  "body": ["static const access = ScopeAccess<${1:Widget}>();$0"]
}
```

**Installing them.** They ship with the package, so they are already on the
machine. For VS Code — and Cursor, Windsurf and Antigravity, which share the
format — copy the snippets into the project:

```sh
mkdir -p .vscode
cp "$(find ~/.pub-cache/hosted/pub.dev -maxdepth 1 -name 'scopo-*' | sort -V | tail -1)"/ide/scopo.code-snippets .vscode/
```

For IntelliJ IDEA and Android Studio there is no import button on the Live
Templates page any more. The file goes into the configuration directory of the
IDE, under `templates/`, named after the group it declares — the XML says
`scopo`, so the file is `scopo.xml` — and the IDE is restarted:

```sh
# Android Studio on macOS; for IntelliJ IDEA the directory is
# ~/Library/Application Support/JetBrains/<product>/
DIR=~/Library/Application\ Support/Google/AndroidStudio<version>/templates
mkdir -p "$DIR"
cp "$(find ~/.pub-cache/hosted/pub.dev -maxdepth 1 -name 'scopo-*' | sort -V | tail -1)"/ide/scopo-live-templates.xml "$DIR/scopo.xml"
```

The group then appears under **Settings → Editor → Live Templates**.

The rest is in
[`ide/README.md`](https://github.com/vi-k/scopo/blob/main/ide/README.md): the
table of all eleven and what is checked about them. The skeletons they insert
are compiled by the package's own gate, and the suite holds each live template
to the context it belongs in; what an editor makes of the file is still
something only an import shows, and Android Studio took it.

## Where to go next

| topic | what it covers |
| --- | --- |
| `ScopeWidget` | the element base every family extends: subscriptions, notify-only rebuilds |
| `ScopeModel`, `ScopeNotifier` | scopes that own a plain object or a `Listenable` |
| `AsyncScope`, `AsyncDataScope` | asynchronous initialization and disposal |
| `AsyncControllerScope` | a scope whose whole content is a controller with a lifecycle of its own |
| `LiteScope` | a scope without a dependency container |
| `Scope` | the full family: dependencies, state, and the four build branches |
| `debug` | the observer, timeouts and what a `tag` looks like in the output |
