part of 'listen.dart';

extension ListenableListenToExtension<L extends Listenable> on L {
  /// Listen to a specific aspect of the [Listenable].
  ///
  /// In the usual case, we listen to all changes of [Listenable].
  ///
  /// This method allows us to call the [listener] only when the [aspect] we
  /// specified has changed.
  ///
  /// Example:
  ///
  /// ```dart
  /// final subscription = listenable.listenTo(
  ///     (listenable) => listenable.counter,
  ///     (listenable, counter) => print(counter),
  /// );
  /// ```
  ///
  /// By default, the previous value is compared to the new value using the
  /// operator [Object.==], but this behavior can be changed using [test].
  ///
  /// Example:
  ///
  /// ```dart
  /// final subscription = listenable.listenTo(
  ///     (listenable) => listenable.data,
  ///     (listenable, data) => print(data),
  ///     test: (previous, current) => identical(previous, current),
  /// );
  /// ```
  ListenableToSubscription<T> listenTo<T extends Object?>(
    T Function(L listenable) aspect,
    void Function(L listenable, T value) listener, {
    bool Function(T previous, T current)? test,
  }) {
    late final ListenableToSubscription<T> subscription;

    void handle() {
      final newValue = aspect(this);
      if (test?.call(subscription._value, newValue) ??
          subscription._value != newValue) {
        subscription._value = newValue;
        listener(this, newValue);
      }
    }

    addListener(handle);

    return subscription =
        ListenableToSubscription._(this, handle, aspect(this));
  }
}

/// A subscription on aspect changes from a [Listenable].
final class ListenableToSubscription<T extends Object?>
    extends ListenableSubscription {
  T _value;

  ListenableToSubscription._(super._listenable, super._callback, this._value)
      : super._();

  T get value => _value;
}
