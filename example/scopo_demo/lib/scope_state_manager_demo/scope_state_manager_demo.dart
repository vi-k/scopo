import 'package:flutter/material.dart';

class ScopeStateManagerDemo extends StatefulWidget {
  const ScopeStateManagerDemo({super.key});

  @override
  State<ScopeStateManagerDemo> createState() => _ScopeStateManagerDemoState();
}

class _ScopeStateManagerDemoState extends State<ScopeStateManagerDemo>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: '1'),
              Tab(text: '2'),
              Tab(text: '3'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                SizedBox(),
                SizedBox(),
                SizedBox(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
