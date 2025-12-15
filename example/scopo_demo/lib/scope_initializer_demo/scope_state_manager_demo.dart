import 'package:flutter/material.dart';

import 'tabs/scope_async_initializer_tab/scope_async_initializer_tab.dart';
import 'tabs/scope_state_builder_tab/scope_state_builder_tab.dart';
import 'tabs/scope_stream_initializer_tab/scope_stream_initializer_tab.dart';

class ScopeStateBuilderDemo extends StatefulWidget {
  const ScopeStateBuilderDemo({super.key});

  @override
  State<ScopeStateBuilderDemo> createState() => _ScopeStateBuilderDemoState();
}

class _ScopeStateBuilderDemoState extends State<ScopeStateBuilderDemo>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return const DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'ScopeStateBuilder'),
              Tab(text: 'ScopeAsyncInitializer'),
              Tab(text: 'ScopeStreamInitializer'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ScopeStateBuilderTab(),
                ScopeAsyncInitializerTab(),
                ScopeStreamInitializerTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
