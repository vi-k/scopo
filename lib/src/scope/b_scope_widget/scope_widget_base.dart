part of '../scope.dart';

/// {@category ScopeWidget}
abstract base class ScopeWidgetBase<W extends ScopeWidgetBase<W>>
    extends ScopeWidgetCore<W, _ScopeWidgetElement<W>> {
  const ScopeWidgetBase({
    super.key,
    super.tag,
    super.child, // Not used by default. You can use it at your own discretion.
  });

  @override
  // ignore: library_private_types_in_public_api
  _ScopeWidgetElement<W> createScopeElement() => _ScopeWidgetElement(this as W);

  Widget build(BuildContext context);

  static W? maybeOf<W extends ScopeWidgetBase<W>>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.maybeOf<W, ScopeContext<W>>(context, listen: listen)?.widget;

  static W of<W extends ScopeWidgetBase<W>>(
    BuildContext context, {
    required bool listen,
  }) =>
      ScopeContext.of<W, ScopeContext<W>>(context, listen: listen).widget;

  static V select<W extends ScopeWidgetBase<W>, V extends Object?>(
    BuildContext context,
    V Function(W widget) selector,
  ) =>
      ScopeContext.select<W, ScopeContext<W>, V>(
        context,
        (context) => selector(context.widget),
      );
}

final class _ScopeWidgetElement<W extends ScopeWidgetBase<W>>
    extends ScopeWidgetElementBase<W, _ScopeWidgetElement<W>>
    implements ScopeInheritedElement<W> {
  _ScopeWidgetElement(super.widget);

  @override
  Widget buildChild() => widget.build(this);
}
