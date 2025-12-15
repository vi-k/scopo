import 'package:flutter/widgets.dart';
import 'package:scopo/scopo.dart';

import 'theme_model.dart';

final class ThemeManager
    extends ScopeNotifierBase<ThemeManager, ThemeModelNotifier> {
  final Widget Function(BuildContext context) builder;

  const ThemeManager({
    super.key,
    required super.create,
    required super.dispose,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) => builder(context);

  static ThemeModel of(BuildContext context, {bool listen = true}) =>
      ScopeNotifierBase.of<ThemeManager, ThemeModelNotifier>(
        context,
        listen: listen,
      ).model;

  static V select<V extends Object>(
    BuildContext context,
    V Function(ThemeModel) selector,
  ) => ScopeNotifierBase.select<ThemeManager, ThemeModelNotifier, V>(
    context,
    (context) => selector(context.model),
  );
}
