part of '../../scope.dart';

/// {@category Scope}
final class ScopeAutoDependenciesProgress {
  final String name;
  final Progress _progress;

  const ScopeAutoDependenciesProgress(this.name, this._progress);

  int get number => _progress.number;
  int get total => _progress.total;
  double get progress => _progress.progress;

  @override
  String toString() => '$name ($_progress)';
}
