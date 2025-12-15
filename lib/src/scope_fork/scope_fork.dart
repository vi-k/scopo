// import 'dart:async';

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';

// import '../environment/scope_config.dart' as log;
// import '../scope_provider/scope_provider.dart';

// part 'scope_fork_state.dart';

// abstract base class ScopeFork<I extends ScopeFork<I, S>, S extends Object>
//     extends StatefulWidget {
//   final Object? tag;
//   final S initialState;

//   const ScopeFork({
//     super.key,
//     this.tag,
//     required this.initialState,
//   });

//   Stream<S> process();

//   /// Method for constructing a subtree in case of initialization error.
//   Widget onError(Object error, StackTrace stackTrace, void Function() restart);

//   Widget onState(S state);

//   @override
//   State<I> createState() => ScopeForkState<I, S>();

//   @override
//   String toStringShort() => '${objectRuntimeType(this, '${ScopeFork<I, S>}')}'
//       '${tag == null ? '' : '($tag)'}';
// }

// base class ScopeForkState<I extends ScopeFork<I, S>, S extends Object>
//     extends State<I> {
//   StreamSubscription<void>? _subscription;
//   late _ScopeForkState<S> _state;

//   @override
//   void initState() {
//     super.initState();
//     _start();
//   }

//   @override
//   void dispose() {
//     _cancel();
//     super.dispose();
//   }

//   void _start() {
//     String source() => log.source(widget, 'process');

//     _state = _ScopeForkSuccess(widget.initialState);

//     _subscription = widget.process().listen(
//       (state) {
//         log.d(source, 'state=$state');
//         if (mounted) {
//           setState(() {
//             _state = _ScopeForkSuccess(state);
//           });
//         }
//       },
//       onError: (Object error, StackTrace stackTrace) {
//         _cancel();

//         log.e(
//           source,
//           'failed',
//           error: error,
//           stackTrace: stackTrace,
//         );

//         if (mounted) {
//           setState(() {
//             _state = _ScopeForkError(error, stackTrace);
//           });
//         }
//       },
//       onDone: () {
//         log.d(source, 'done');
//       },
//     );
//   }

//   void _cancel() {
//     _subscription?.cancel();
//     _subscription = null;
//   }

//   void restart() {
//     _cancel();
//     _start();
//   }

//   @override
//   Widget build(BuildContext _) {
//     return ScopeProvider<ScopeForkState<I, S>>.value(
//       value: this,
//       builder: (context) {
//         ScopeProvider.depend<ScopeForkState<I, S>>(context);
//         return switch (_state) {
//           _ScopeForkError(:final error, :final stackTrace) =>
//             widget.onError(error, stackTrace, restart),
//           _ScopeForkSuccess(:final state) => widget.onState(state),
//         };
//       },
//     );
//   }

//   @override
//   String toStringShort() => '${ScopeForkState<I, S>}(_state: $_state)';
// }
