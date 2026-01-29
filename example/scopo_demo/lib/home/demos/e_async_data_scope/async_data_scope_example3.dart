import 'package:flutter/material.dart';

import 'counter_scope.dart';

int _num = 0;

class AsyncDataScopeExample3 extends StatefulWidget {
  const AsyncDataScopeExample3({super.key});

  @override
  State<AsyncDataScopeExample3> createState() => _AsyncDataScopeExample3State();
}

class _AsyncDataScopeExample3State extends State<AsyncDataScopeExample3> {
  final _childGlobalKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _num++;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: CounterScope(
              scopeKey: AsyncDataScopeExample3,
              title: '$AsyncDataScopeExample3 (scopeKey + parent & child)',
              childScope: Center(
                child: CounterScope(
                  key: _childGlobalKey,
                  debugSource: AsyncDataScopeExample3,
                  debugName: 'child $_num',
                ),
              ),
              debugSource: AsyncDataScopeExample3,
              debugName: 'parent $_num',
            ),
          ),
        ],
      ),
    );
  }
}
