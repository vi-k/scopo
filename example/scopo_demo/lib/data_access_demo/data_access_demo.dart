import 'package:flutter/material.dart';

import 'tabs/scope_notifier_tab/scope_notifier_tab.dart';
import 'tabs/scope_provider_base_tab/scope_provider_base_tab.dart';
import 'tabs/scope_provider_tab/scope_provider_tab.dart';

class DataAccessDemo extends StatefulWidget {
  const DataAccessDemo({super.key});

  @override
  State<DataAccessDemo> createState() => _DataAccessDemoState();
}

class _DataAccessDemoState extends State<DataAccessDemo>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return const DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'ScopeProvider'),
              Tab(text: 'ScopeNotifier'),
              Tab(text: 'Scope(Provider/Notifier)Base'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ScopeProviderTab(),
                ScopeNotifierTab(),
                ScopeProviderBaseTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
