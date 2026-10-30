/// Asynchronous resources owned by the widget tree: a scope initializes what
/// its subtree needs, cancels that initialization if the subtree leaves first,
/// provides the result to its descendants, and disposes of it in order — after
/// its child scopes, and before the next owner of the same `scopeKey`.
library;

// These are the kernel names used to drive an initialization and read its
// outcome. Listing them keeps future kernel helpers out of scopo's API.
export 'package:async_job/async_job.dart'
    show
        CancelReason,
        Cancelled,
        DeferredJob,
        Done,
        Failed,
        HandlerCancelReason,
        Job,
        JobAnswerer,
        JobContext,
        JobErrorAnswer,
        JobObserver,
        ManualCancelReason,
        Outcome,
        ParentCancelReason,
        SiblingCancelReason,
        TimeoutCancelReason;

// Listed rather than hidden. `hide` names what stays in, so the next internal
// helper added beside `notifyObserver` and the two resolvers would join the
// public API without anybody deciding that -- and a name is public from the
// moment it ships. The line below already says it the right way round.
export 'src/environment/scope_config.dart'
    show
        ScopeCompositeObserver,
        ScopeConfig,
        ScopeErrorRoute,
        ScopeObservable,
        ScopeObserver,
        ScopePhase,
        ScopePrintObserver,
        ScopeTimeout;
export 'src/scope/scope.dart';
export 'src/utils/compare_utils.dart';
// The rebuild counter beside it is the package's own bookkeeping: written by
// `ScopeWidgetElementBase`, read by `isBuilding`, and no business of a
// consumer.
export 'src/utils/is_building.dart' show IsBuildingExtension;
// `listen` and `select` on a `Listenable` are not here but in
// `package:scopo/listenable.dart`: extensions on the framework's own type meet
// those of every other package that has one, and the import is the choice.
export 'src/utils/listenable/listenable_selector.dart';
export 'src/utils/listenable/listenable_view.dart';
export 'src/utils/listenable/state_as_notifier.dart';
export 'src/utils/progress_iterator/progress_iterator.dart';
export 'src/utils/screenshot_replacer.dart';
