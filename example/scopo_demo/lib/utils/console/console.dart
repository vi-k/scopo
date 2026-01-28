import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:scopo/scopo.dart';

final console = Console();

final class Console with ChangeNotifier {
  static const int _maxLines = 100;

  final Map<Object, ({List<String> lines, List<String> view})> _cache = {};

  Iterable<Object> get sources => _cache.keys;

  List<String> lines(Object source) => _cache[source]?.view ?? const [];

  void log(Object source, String message) {
    final lines = (_cache[source]?.lines?..add(message)) ?? [message];
    if (lines.length > _maxLines) {
      lines.removeAt(0);
    }

    // Храним view, чтобы подписчики могли узнавать, изменились ли lines:
    // lines никогда не меняется, view меняется каждый раз.
    _cache[source] = (lines: lines, view: UnmodifiableListView(lines));
    notifyListeners();
  }

  void clear(Object source) {
    _cache.remove(source);
    notifyListeners();
  }

  void clearAll() {
    _cache.clear();
    notifyListeners();
  }

  @override
  void notifyListeners() {
    SchedulerBinding.instance.runOutsideFrame(super.notifyListeners);
  }
}
