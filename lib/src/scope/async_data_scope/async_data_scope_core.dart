part of '../scope.dart';

/// {@category AsyncDataScope}
abstract base class AsyncDataScopeCore<
    W extends AsyncDataScopeCore<W, E, T>,
    E extends AsyncDataScopeElementBase<W, E, T>,
    T extends Object?> extends AsyncScopeCore<W, E> {
  /// Creates the widget half of a scope producing a value.
  const AsyncDataScopeCore({
    super.key,
    super.tag,
    super.child, // Not used by default. You can use it at your own discretion.
  });

  /// The element of the nearest scope [W] above [context], or `null`.
  static E? maybeOf<W extends AsyncDataScopeCore<W, E, T>,
          E extends AsyncDataScopeElementBase<W, E, T>, T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.maybeOf<W, E>(
        context,
        listen: listen,
      );

  /// The element of the nearest scope [W] above [context].
  ///
  /// Throws when there is none.
  static E of<W extends AsyncDataScopeCore<W, E, T>,
          E extends AsyncDataScopeElementBase<W, E, T>, T extends Object?>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.of<W, E>(
        context,
        listen: listen,
      );

  /// Subscribes to one value of the scope and returns it.
  static V select<
          W extends AsyncDataScopeCore<W, E, T>,
          E extends AsyncDataScopeElementBase<W, E, T>,
          T extends Object?,
          V extends Object?>(
    BuildContext context,
    V Function(E element) selector,
  ) =>
      ScopeContext.select<W, E, V>(
        context,
        selector,
      );
}

/// {@category AsyncDataScope}
abstract base class AsyncDataScopeElementBase<
        W extends AsyncDataScopeCore<W, E, T>,
        E extends AsyncDataScopeElementBase<W, E, T>,
        T extends Object?> extends AsyncScopeElementBase<W, E>
    implements AsyncDataScopeContext<W, T> {
  //
  // Overriding block
  //

  @override
  Object? get scopeKey => null;

  @override
  Duration? get pauseAfterInitialization => null;

  /// The initialization, ending with the value.
  Future<T> initDataAsync(ScopeInitContext ctx);

  @override
  FutureOr<void> disposeScope() {}

  @override
  Widget buildOnState(AsyncScopeState state);

  //
  // End of overriding block
  //

  @override
  T get data => _hasData ? _data as T : throw StateError('Not initialized');

  T? _data;

  /// Whether [_data] holds the value the initialization produced.
  ///
  /// Kept apart from the value, because for a nullable [T] the value cannot
  /// answer for itself: `null` is something the initialization may legitimately
  /// produce, and reading it as "nothing yet" made [data] hand out a value the
  /// scope had never been given.
  ///
  /// It is set only when the job ends with [Done], a little before the
  /// model says [AsyncScopeReady] — the model update waits for the end of the
  /// frame, or for the whole of `pauseAfterInitialization`. The teardown reads
  /// [data] in exactly that window, so this is the moment that matters and not
  /// the state of the model.
  bool _hasData = false;

  @override
  bool get hasData => _hasData;

  @override
  T? get dataOrNull => _data;

  /// Creates the element of a scope producing a value.
  AsyncDataScopeElementBase(super.widget);

  /// Sealed: this is where the value is caught on its way past, and the
  /// family has nothing to offer without it. The hook to write is
  /// [initDataAsync]; overriding this one instead would leave [data] empty
  /// for good, and the analyzer would say nothing about it.
  @nonVirtual
  @override
  Future<void> runInitBody(ScopeInitContext ctx) async {
    final data = await initDataAsync(ctx);

    // `ctx.onDiscard` routes a value the scope never accepted through the
    // kernel's cleanup stack to `releaseLateData`. Once accepted, the value is
    // held by the field, so the field is filled only in the `Done` branch,
    // when the outcome is known. Storing it in the body would let cancellation
    // during cleanup release a value the field already holds.
    ctx.onDiscard(() async {
      _acceptInitValue = null;
      await releaseLateData(data);
    });

    // Refuse a second initialization before it can replace the held value.
    // A guard in the layer above would run after the field had been written:
    // the model would stay as it was and the dependents would hear nothing,
    // but `data` would return the newcomer. The value the scope had actually
    // been using would be lost to the teardown, with nobody left to release it.
    if (_hasData) {
      throw StateError('$W already initialized');
    }

    _acceptInitValue = () {
      _data = data;
      _hasData = true;
    };
  }

  /// Releases the value the initialization produced; awaited.
  @protected
  FutureOr<void> disposeData(T data);

  /// Releases a value the body produced after the scope had given up.
  ///
  /// It never reached [data], so the release takes it directly rather than
  /// through [disposeScope], which reads the field — and it happens only
  /// while there is still a scope to release it with. A family that promises
  /// more than that overrides this: `AsyncControllerScope` releases its
  /// controller on every path there is, including this one, and has its own
  /// release written for exactly that.
  @protected
  Future<void> releaseLateData(T data) async {
    if (canReleaseAfterCancellation) {
      await disposeData(data);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<T?>('data', _data));
  }
}
