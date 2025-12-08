// import 'dart:async';

// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';

// import '../environment/scope_config.dart' as log;

// part 'lite_scope_state.dart';

// abstract base class LiteScope<L extends LiteScope<L, S>, S extends Object>
//     extends StatefulWidget {
//   final Object? tag;
//   final S initialState;

//   const LiteScope({
//     super.key,
//     this.tag,
//     required this.initialState,
//   });

//   Stream<S> init();

//   /// Method for constructing a subtree in case of initialization error.
//   Widget onError(Object error, StackTrace stackTrace, void Function() restart);

//   Widget onState(S state);

//   @override
//   State<L> createState() => _LiteScopeState<L, S>();

//   @override
//   String toStringShort() => '${objectRuntimeType(this, '${LiteScope<L, S>}')}'
//       '${tag == null ? '' : '($tag)'}';
// }

// base class _LiteScopeState<L extends LiteScope<L, S>, S extends Object>
//     extends State<L> {
//   StreamSubscription<void>? _subscription;
//   late LiteScopeState<S> _state;

//   @override
//   void initState() {
//     super.initState();

//     _start();
//   }

//   @override
//   void dispose() {
//     _unsubscribe();
//     super.dispose();
//   }

//   void _start() {
//     String source() => log.source(widget, 'init');

//     _state = LiteScopeSuccess(widget.initialState);

//     _subscription = widget.init().listen(
//       (state) {
//         if (mounted) {
//           log.d(source, 'state=$state');
//           setState(() {
//             _state = LiteScopeSuccess(state);
//           });
//         }
//       },
//       onError: (Object error, StackTrace stackTrace) {
//         _unsubscribe();

//         log.e(
//           source,
//           'failed',
//           error: error,
//           stackTrace: stackTrace,
//         );

//         setState(() {
//           _state = LiteScopeError(error, stackTrace);
//         });
//       },
//       onDone: () {
//         log.d(source, 'done');
//       },
//     );
//   }

//   void _unsubscribe() {
//     _subscription?.cancel();
//     _subscription = null;
//   }

//   void _restart() {
//     _unsubscribe();
//     _start();
//   }

//   @override
//   Widget build(BuildContext _) {
//     return switch (_state) {
//       LiteScopeSuccess(:final state) => widget.onState(state),
//       LiteScopeError(:final error, :final stackTrace) =>
//         widget.onError(error, stackTrace, _restart),
//     };
//   }

//   @override
//   String toStringShort() => '${_LiteScopeState<L, S>}(_state: $_state)';
// }
