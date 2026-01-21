import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

import '../../common/data/real_services/key_value_storage.dart';

part 'static_themes.dart';
part 'theme_model.dart';

final class ThemeManager extends ScopeNotifierBase<ThemeManager, ThemeModel> {
  final Widget Function(BuildContext context) builder;

  ThemeManager({
    super.key,
    required this.builder,
    required KeyValueStorage keyValueService,
  }) : super(
          create: (context) => _ThemeModelNotifier(
            keyValueService: keyValueService,
            systemBrightness: () => MediaQuery.of(context).platformBrightness,
          ),
          dispose: (model) => (model as _ThemeModelNotifier).dispose(),
        );

  @override
  Widget build(BuildContext context) {
    return builder(context);
  }

  static ThemeModel of(BuildContext context, {bool listen = true}) =>
      ScopeNotifierBase.of<ThemeManager, ThemeModel>(
        context,
        listen: listen,
      ).model;

  static V select<V extends Object>(
    BuildContext context,
    V Function(ThemeModel) selector,
  ) =>
      ScopeNotifierBase.select<ThemeManager, ThemeModel, V>(
        context,
        (context) => selector(context.model),
      );
}
