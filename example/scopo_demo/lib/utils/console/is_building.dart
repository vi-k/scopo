import 'package:flutter/scheduler.dart';

bool get isBuilding {
  final phase = SchedulerBinding.instance.schedulerPhase;
  return phase == SchedulerPhase.persistentCallbacks;
}

void runOutsideFrame(void Function() action) {
  if (isBuilding) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      action();
    });
  } else {
    action();
  }
}
