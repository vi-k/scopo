part of '../scope.dart';

/// Whether a registration arriving right now belongs to a build of [context].
///
/// What a dependent asked for is remembered per build, and the boundary
/// between one build and the next is taken from the frame -- Flutter offers no
/// hook for "this dependent is about to build". A registration is therefore
/// safe only where **everything** the dependent asked for is asked for again
/// in the same breath: the registrations of one dependent that arrive on
/// different frames do not add up, the later ones replace the earlier ones,
/// and what they replaced goes stale with nothing said.
///
/// Two places have that property. The dependent's own `build`, which produces
/// all of its registrations at once. And a builder the framework runs from
/// layout for an element that has no `build` of its own but re-runs that
/// builder whole: `LayoutBuilder` and `SliverLayoutBuilder` (both are a
/// `ConstrainedLayoutBuilder`, and `OrientationBuilder` hands its user the
/// context of the first), and the delegate of a persistent header, which
/// builds its one child from scratch whenever the shrink offset changes.
///
/// The item builder of a lazy list looks like the second and is not: its items
/// are built a few at a time and across frames, all of them registering on the
/// list's own element, so the items brought into view by a scroll wipe what
/// the items above them had asked for. It is refused, and the way out is a
/// `Builder` around the item -- which is better code anyway, since a change
/// then wakes the one item instead of the whole list. Both shapes were
/// measured before this was narrowed:
/// `docs/records/2026-09-22[3]-lazy-registration-report.md`.
///
/// None of this reaches release. `debugDoingBuild` and
/// `RenderObject.debugActiveLayout` are both set inside `assert(() {…}())`, so
/// in release they answer "no build anywhere" for every caller -- which is why
/// this can only ever be an assertion, and why the mistake it names is silent
/// in a release build.
bool _debugRegistrationBelongsToABuild(BuildContext context) {
  // The dependent's own build.
  if (context.debugDoingBuild) {
    return true;
  }

  // Everything else this rule allows is a builder run from layout. Outside
  // one, there is nothing a registration could belong to: a timer, a gesture,
  // an `await` that came back between frames, a lifecycle hook of the
  // dependent -- `didChangeDependencies` above all.
  if (RenderObject.debugActiveLayout == null) {
    return false;
  }

  // A layout builder runs its builder whole on every layout, so the
  // registrations it takes are all of them. The context has to be the
  // builder's own: a closure that captured the context of the widget around it
  // registers on an element that is not being rebuilt at all.
  if (context.widget is ConstrainedLayoutBuilder) {
    return true;
  }

  // A persistent header does the same through a delegate rather than through a
  // builder: one child, built from scratch whenever the shrink offset changes.
  return context is RenderObjectElement &&
      context.renderObject is RenderSliverPersistentHeader;
}

/// {@category base}
abstract base class ScopeInheritedWidget extends InheritedWidget {
  /// Names this particular scope in the log.
  ///
  /// Two scopes of the same type are otherwise told apart only by a short
  /// hash. See the `debug` topic for the format.
  final Object? tag;

  /// Creates the inherited widget of a scope.
  ///
  /// The `child` is not what a scope shows — that is [
  /// ScopeInheritedElement.buildChild] — and the default is a placeholder
  /// that refuses to build.
  const ScopeInheritedWidget({
    super.key,
    this.tag,
    // Not used by default. You can use it at your own discretion.
    super.child = const _NullWidget(),
  });
}

/// The default `child` of a [ScopeInheritedWidget]: a placeholder that refuses
/// to become an element.
///
/// A scope builds what it shows through `buildChild()`, and the `child` it is
/// constructed with is there for a family that wants the plain
/// `InheritedWidget` behaviour and reads it itself. Nothing in the package does,
/// so building this one means a family returned a `child` nobody passed --
/// which is worth saying out loud rather than raising a bare
/// [UnimplementedError] from somewhere inside the framework.
final class _NullWidget extends Widget {
  const _NullWidget();

  @override
  Element createElement() => throw UnimplementedError(
        'A scope built the placeholder `child` of `ScopeInheritedWidget`. A '
        'scope builds its own subtree through `buildChild()`; the `child` it '
        'is constructed with is used only by a family that reads it, and this '
        'is the default nobody passed one for. Pass a `child` to the scope, or '
        'return the subtree from `buildChild()`.',
      );
}

/// The element whose initialization hook is running right now.
///
/// Written only from inside `assert`s, so it costs nothing in release builds.
/// It is what lets the lookup below tell a subscription taken from the hook --
/// which can never be honoured -- from an ordinary one.
Element? _debugInitializingElement;

/// Reports a failure that has no caller left to be raised at.
///
/// A teardown runs in halves and stages, each guarded on its own, and every
/// one of them reaches user code. Only the first failure can be passed on --
/// a throw takes one -- and the ones behind it used to end in a log line that
/// is off by default, which is the same as losing them. This is the trade the
/// rest of the package makes for such failures: reported, and the teardown
/// goes on.
void _reportFailure(Object error, StackTrace stackTrace, [String? context]) {
  FlutterError.reportError(
    FlutterErrorDetails(
      exception: error,
      stack: stackTrace,
      library: 'scopo',
      context: context == null ? null : ErrorDescription(context),
    ),
  );
}

/// {@category base}
abstract interface class ScopeContext<W extends ScopeInheritedWidget> {
  /// The widget of this scope.
  W get widget;

  /// The context of the nearest scope [W] above [context], or `null`.
  ///
  /// With `listen: true` the caller is subscribed to every change of that
  /// scope; with `listen: false` it is not subscribed at all.
  static C? maybeOf<W extends ScopeInheritedWidget, C extends ScopeContext<W>>(
    BuildContext context, {
    required bool listen,
  }) =>
      _find<W, C, void>(context, listen: listen)?.$1;

  /// The context of the nearest scope [W] above [context].
  ///
  /// Throws when there is no such scope. [maybeOf] returns `null` instead.
  static C of<W extends ScopeInheritedWidget, C extends ScopeContext<W>>(
    BuildContext context, {
    required bool listen,
  }) =>
      _find<W, C, void>(context, listen: listen)?.$1 ?? _throwNotFound<W>();

  /// Subscribes to one value of the scope and returns it.
  ///
  /// The caller is rebuilt only when `selector` returns something different
  /// from what it returned during its last build. Throws when there is no
  /// such scope.
  static V select<W extends ScopeInheritedWidget, C extends ScopeContext<W>,
          V extends Object?>(
    BuildContext context,
    V Function(C context) selector,
  ) =>
      (_find<W, C, V>(context, listen: true, selector: selector) ??
              _throwNotFound<W>())
          .$2 as V;

  static (C, V?)? _find<W extends ScopeInheritedWidget,
      C extends ScopeContext<W>, V extends Object?>(
    BuildContext context, {
    required bool listen,
    V Function(C)? selector,
  }) {
    assert(() {
      if (listen && identical(context, _debugInitializingElement)) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'A scope cannot be subscribed to from the initialization hook.',
          ),
          ErrorDescription(
            'The hook runs once, before the first build, and is never called '
            'again, so a subscription taken there rebuilds the subtree while '
            'the value the hook read stays behind.',
          ),
          ErrorHint(
            'Look the scope up with `listen: false` here, and subscribe from '
            '`buildChild()` or from the widgets below instead.',
          ),
          context.describeElement('The scope that tried to subscribe was'),
        ]);
      }

      return true;
    }());

    assert(() {
      if (listen && !_debugRegistrationBelongsToABuild(context)) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('A scope can only be subscribed to from a build.'),
          ErrorDescription(
            'What a dependent asked for is remembered per build, and the '
            'boundary between one build and the next is taken from the frame '
            '-- Flutter offers no hook for "this dependent is about to build". '
            'The registrations one dependent makes on different frames '
            'therefore do not add up: the later ones replace the earlier ones, '
            'and whatever they replaced stops being told about changes.',
          ),
          ErrorDescription(
            '`didChangeDependencies` is the usual way to get here: it runs in '
            'the same frame as the build after it, so the subscription looks '
            'like it works, and then disappears on the first rebuild that '
            'comes from the parent instead of from a change.',
          ),
          ErrorHint(
            'Subscribe from `build` and read the value there. The builder of a '
            '`LayoutBuilder` or a `SliverLayoutBuilder` counts as one, because '
            'it re-runs whole -- but only through the context it is given, not '
            'through the context of a widget above it.',
          ),
          ErrorHint(
            'The item builder of a lazy list does not count: its items are '
            'built a few at a time and across frames, so the ones a scroll '
            'brings into view would leave the ones above them subscribed to '
            'nothing. Put a `Builder` around the item and subscribe from '
            'there, which also wakes that item alone instead of the whole '
            'list.',
          ),
          ErrorHint(
            'To react to a change rather than to show it, keep the '
            'subscription in `build` and look the scope up with '
            '`listen: false` from `didChangeDependencies`.',
          ),
          context.describeElement('The dependent that tried to subscribe was'),
        ]);
      }

      return true;
    }());

    final element = context.getElementForInheritedWidgetOfExactType<W>();
    if (element == null) {
      if (listen) {
        // Records the dependency the lookup could not satisfy. Flutter
        // remembers those so that a widget carried under a matching ancestor
        // later -- by a `GlobalKey`, say -- is told its dependencies changed
        // and reads the scope again. `getElementForInheritedWidgetOfExactType`
        // above records nothing at all, so without this the widget went on
        // showing whatever it read when there was no scope above it.
        context.dependOnInheritedWidgetOfExactType<W>();
      }

      return null;
    }

    final scopeContext = element is C
        ? element as C
        : throw Exception('The element of $W is not $C');

    if (!listen) {
      return (scopeContext, null);
    }

    V? value;
    if (selector == null) {
      context.dependOnInheritedElement(element);
    } else {
      value = selector(scopeContext);
      context.dependOnInheritedElement(element, aspect: (value, selector));
    }

    return (scopeContext, value);
  }

  static Never _throwNotFound<W extends InheritedWidget>() {
    throw Exception('$W not found in the context');
  }
}

/// {@category base}
abstract interface class ScopeInheritedElement<W extends ScopeInheritedWidget>
    implements ScopeContext<W> {
  @override
  W get widget;

  /// Called once, after the element is mounted and before its first
  /// [buildChild].
  ///
  /// If it throws, the failure is terminal: the hook is not attempted again,
  /// the scope shows an error instead of its subtree, and every later build
  /// reports the same failure. Subscribing to another scope from here is not
  /// supported and is caught by an assertion; looking one up with
  /// `listen: false` is, since the element is already connected to its
  /// ancestors.
  ///
  /// Everything the scope owns is acquired here and released in [dispose].
  @mustCallSuper
  void init();

  /// Called when the element is unmounted, unless [init] never ran at all.
  ///
  /// An [init] that threw halfway is cleaned up here too, so whatever it took
  /// before it failed is given back. Implementations therefore have to expect
  /// a partially initialized scope.
  @mustCallSuper
  void dispose();

  /// Builds what the scope shows.
  Widget buildChild();
}
