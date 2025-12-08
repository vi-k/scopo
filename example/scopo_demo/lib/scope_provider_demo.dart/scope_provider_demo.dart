import 'package:flutter/material.dart';

import 'tabs/scope_listenable_tab/scope_listenable_provider_tab.dart';
import 'tabs/scope_provider_base_tab/scope_provider_base_tab.dart';
import 'tabs/scope_notifier_tab/scope_notifier_tab.dart';
import 'tabs/scope_provider_tab/scope_provider_tab.dart';

class ScopeProviderDemo extends StatefulWidget {
  const ScopeProviderDemo({super.key});

  @override
  State<ScopeProviderDemo> createState() => _ScopeProviderDemoState();
}

class _ScopeProviderDemoState extends State<ScopeProviderDemo>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'ScopeProvider'),
              Tab(text: 'ScopeListenableProvider'),
              Tab(text: 'ScopeNotifier'),
              Tab(text: 'ScopeProviderBase'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ScopeProviderTab(),
                ScopeListenableProviderTab(),
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
