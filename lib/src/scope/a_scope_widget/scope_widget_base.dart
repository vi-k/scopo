part of '../scope.dart';

abstract base class ScopeWidgetBase<W extends ScopeWidgetBase<W>>
    extends ScopeWidgetCore<W, ScopeWidgetElement<W>> {
  const ScopeWidgetBase({
    super.key,
    super.tag,
  });

  @override
  ScopeWidgetElement<W> createScopeElement() => ScopeWidgetElement(this as W);

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

final class ScopeWidgetElement<W extends ScopeWidgetBase<W>>
    extends ScopeWidgetElementBase<W, ScopeWidgetElement<W>>
    implements ScopeInheritedElement<W> {
  ScopeWidgetElement(super.widget);

  @override
  Widget buildChild() => widget.build(this);
}
