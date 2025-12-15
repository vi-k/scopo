import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SizedTabBar extends TabBar {
  final double height;

  SizedTabBar({
    super.key,
    required this.height,
    required List<Widget> tabs,
    super.controller,
    super.isScrollable = false,
    super.padding,
    super.indicatorColor,
    super.automaticIndicatorColorAdjustment = true,
    super.indicatorWeight = 2.0,
    super.indicatorPadding = EdgeInsets.zero,
    super.indicator,
    super.indicatorSize,
    super.dividerColor,
    super.dividerHeight,
    super.labelColor,
    super.labelStyle,
    super.labelPadding,
    super.unselectedLabelColor,
    super.unselectedLabelStyle,
    super.dragStartBehavior = DragStartBehavior.start,
    super.overlayColor,
    super.mouseCursor,
    super.enableFeedback,
    super.onTap,
    super.onHover,
    super.onFocusChange,
    super.physics,
    super.splashFactory,
    super.splashBorderRadius,
    super.tabAlignment,
    super.textScaler,
    super.indicatorAnimation,
  }) : super(
         tabs: tabs
             .map((e) => SizedBox(height: height, child: e))
             .toList(growable: false),
       );

  @override
  Size get preferredSize => Size.fromHeight(height + indicatorWeight);
}
