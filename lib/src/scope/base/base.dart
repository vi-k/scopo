part of '../scope.dart';

/// Whether a registration arriving right now belongs to a build of [context].
///
/// A build is not only what raises `debugDoingBuild`. An element that builds
/// its children lazily runs a builder of its own, and the registrations that
/// builder takes belong to it as surely as the ones a `build()` takes:
/// `LayoutBuilder`, `OrientationBuilder` and `SliverLayoutBuilder` from
/// `performLayout`, the item builders of the lazy lists from `performLayout`
/// on one frame and from the element's own `performRebuild` on the next --
/// the build phase, with no layout in progress at all. `debugDoingBuild` is
/// raised for none of them (a `RenderObjectElement` raises it around
/// `updateRenderObject` alone), so asking that flag by itself refused working
/// and very common patterns, and refused them in debug only.
///
/// What the assertion exists for is the opposite: a registration taken from a
/// hook of the dependent itself, `didChangeDependencies` above all. It is told
/// apart by the dependent rather than by the phase -- the framework is
/// rebuilding it, and an element stays dirty until its own `build` returns,
/// while an element running a builder for somebody else has been cleaned
/// before the call. Measured on twelve points of one frame; the table is in
/// `docs/records/2026-09-22[1]-subscription-boundary-report.md`.
///
/// None of this reaches release. `debugDoingBuild`, `BuildOwner.debugBuilding`
/// and `RenderObject.debugActiveLayout` are all set inside `assert(() {…}())`,
/// so in release they answer "no build anywhere" for every caller -- which is
/// why this can only ever be an assertion, and why the mistake it names is
/// silent in a release build. `Element.dirty` is the one input here that is
/// real state.
bool _debugRegistrationBelongsToABuild(BuildContext context) {
  // The dependent's own build.
  if (context.debugDoingBuild) {
    return true;
  }

  // Nothing is being built at all: a timer, a gesture, an `await` that came
  // back between frames. This is the mistake in its plainest form.
  if (!(context.owner?.debugBuilding ?? false)) {
    return false;
  }

  // A builder the framework runs on behalf of an element that builds its
  // children lazily. Only a `RenderObjectElement` does that, and it has no
  // hook a subscription could be taken from by mistake: the only user code
  // holding its context is the builder.
  if (context is RenderObjectElement) {
    return true;
  }

  // A layout callback that reads the scope through the context of a widget
  // above it -- the closure captures the enclosing `build`'s context instead
  // of its own. The dependent is not being rebuilt there, so its registration
  // is re-taken by the same callback on every layout. What is being rebuilt
  // under a layout callback, and is not inside its own `build`, is a
  // `didChangeDependencies`.
  return RenderObject.debugActiveLayout != null &&
      context is Element &&
      !context.dirty;
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
            '-- Flutter offers no hook for "this dependent is about to build" '
            '-- so a registration made outside a build belongs to whichever '
            'build shares its frame, and is dropped by the first build that '
            'does not.',
          ),
          ErrorDescription(
            '`didChangeDependencies` is the usual way to get here: it runs in '
            'the same frame as the build after it, so the subscription looks '
            'like it works, and then disappears on the first rebuild that '
            'comes from the parent instead of from a change.',
          ),
          ErrorHint(
            'Subscribe from `build` and read the value there -- the builder '
            'of a `LayoutBuilder` and the item builder of a lazy list count '
            'as one.',
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
