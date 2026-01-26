import 'package:flutter/material.dart';

import 'counter_scope.dart';

int _num = 0;

class StreamScopeExample3 extends StatefulWidget {
  const StreamScopeExample3({super.key});

  @override
  State<StreamScopeExample3> createState() => _StreamScopeExample3State();
}

class _StreamScopeExample3State extends State<StreamScopeExample3> {
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
              scopeKey: StreamScopeExample3,
              title: '$StreamScopeExample3 (parent & child)',
              childScope: Center(
                child: CounterScope(
                  debugSource: StreamScopeExample3,
                  debugName: 'child $_num',
                ),
              ),
              debugSource: StreamScopeExample3,
              debugName: 'parent $_num',
            ),
          ),
        ],
      ),
    );
  }
}
