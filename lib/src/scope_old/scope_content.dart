// part of 'scope.dart';

// final class _ScopeContent<S extends Scope<S, D, C>, D extends ScopeDeps,
//     C extends ScopeContent<S, D, C>> extends StatefulWidget {
//   final D deps;
//   final C Function() createContent;

//   const _ScopeContent({
//     required GlobalKey<C> super.key,
//     required this.deps,
//     required this.createContent,
//   });

//   @override
//   // ignore: no_logic_in_create_state
//   State<_ScopeContent<S, D, C>> createState() => createContent();

//   @override
//   String toStringShort() => '$C';
// }

// /// Holds the state and logic for the UI within the [Scope].
// ///
// /// It acts as a [Listenable] to rebuild widgets when state changes.
// abstract base class ScopeContent<S extends Scope<S, D, C>, D extends ScopeDeps,
//         C extends ScopeContent<S, D, C>> extends State<_ScopeContent<S, D, C>>
//     implements Listenable {
//   ChangeNotifier? _notifier;

//   @override
//   Never get widget => throw UnimplementedError();

//   D get deps => super.widget.deps;

//   Future<void> close() async {
//     await Scope._stateOf<S, D, C>(context)?._close();
//   }

//   @override
//   void addListener(VoidCallback listener) {
//     (_notifier ??= ChangeNotifier()).addListener(listener);
//   }

//   @override
//   void removeListener(VoidCallback listener) {
//     _notifier?.removeListener(listener);
//   }

//   @protected
//   void notifyListeners() {
//     // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
//     _notifier?.notifyListeners();
//   }

//   @mustCallSuper
//   @override
//   void dispose() {
//     _notifier?.dispose();
//     super.dispose();
//   }
// }
