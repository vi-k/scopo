part of '../../scope.dart';

/// {@category Scope}
final class ScopeQueueProgress {
  final String name;
  final Progress _progress;

  const ScopeQueueProgress(this.name, this._progress);

  int get number => _progress.number;
  int get total => _progress.total;
  double get progress => _progress.progress;

  @override
  String toString() => '$name ($_progress)';
}
