import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../environment/scope_config.dart';
import '../utils/lifecycle_coordinator/lifecycle_coordinator.dart';
import '../utils/progress_iterator/double_progress_iterator.dart';
import '../utils/screenshot_replacer.dart';

part 'a_scope_widget/base.dart';
part 'a_scope_widget/scope_widget_base.dart';
part 'a_scope_widget/scope_widget_core.dart';
part 'b_scope_model/scope_model.dart';
part 'b_scope_model/scope_model_base.dart';
part 'b_scope_model/scope_model_core.dart';
part 'b_scope_model/base.dart';
part 'c_scope_notifier/scope_notifier.dart';
part 'c_scope_notifier/scope_notifier_base.dart';
part 'c_scope_notifier/scope_notifier_core.dart';
part 'd_scope_state_model/scope_state_model.dart';
part 'd_scope_state_model/scope_state_with_error_model.dart';
part 'f_scope_async_initializer/scope_async_initializer.dart';
part 'f_scope_async_initializer/scope_async_initializer_base.dart';
part 'f_scope_async_initializer/scope_async_initializer_core.dart';
part 'e_scope_initializer/scope_initializer_context.dart';
part 'e_scope_initializer/scope_initializer_mixin.dart';
part 'e_scope_initializer/scope_initializer_model.dart';
part 'e_scope_initializer/scope_initializer_state.dart';
part 'g_scope_stream_initializer/scope_init_state.dart';
part 'g_scope_stream_initializer/scope_stream_initializer.dart';
part 'g_scope_stream_initializer/scope_stream_initializer_base.dart';
part 'g_scope_stream_initializer/scope_stream_initializer_core.dart';
part 'h_scope/scope.dart';
part 'h_scope/scope_consumer.dart';
part 'h_scope/scope_dependencies.dart';
part 'h_scope/scope_dependencies_queue.dart';
part 'h_scope/scope_state.dart';
