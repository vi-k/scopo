import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scopo/scopo.dart';

import 'utils/settle.dart';

void main() {
  testWidgets('the documented initialization recipe reaches the ready screen', (
    tester,
  ) async {
    final title = Completer<String>();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    await tester.pumpWidget(
      MaterialApp(home: TitleScope(loadTitle: () => title.future)),
    );
    await settle(
      tester,
      until: () => find.byType(CircularProgressIndicator).hasFound,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('ready'), findsNothing);

    title.complete('ready');
    await tester.pump();
    await tester.pump();

    expect(find.text('ready'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    final document = File('doc/lite_scope.md').readAsStringSync();
    final recipe = document
        .split('## Two initializations')
        .last
        .split('```dart\n')[1]
        .split('```')
        .first;
    final source = File(
      'test/lite_scope_initialization_recipe_test.dart',
    ).readAsStringSync();
    expect(
      recipe,
      source.substring(source.indexOf('\nfinal class TitleScope ') + 1),
    );
  });

  testWidgets('initialization without setState leaves the own build loading', (
    tester,
  ) async {
    final title = Completer<String>();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    await tester.pumpWidget(
      MaterialApp(home: _WithoutRebuild(loadTitle: () => title.future)),
    );
    await settle(
      tester,
      until: () => find.byType(CircularProgressIndicator).hasFound,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    title.complete('ready');
    await tester.pump();
    await tester.pump();

    final state = tester.state<_WithoutRebuildState>(
      find.byElementPredicate(
        (element) =>
            element is StatefulElement && element.state is _WithoutRebuildState,
      ),
    );
    expect(state.isInitialized, isTrue);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('ready'), findsNothing);
  });
}

final class _WithoutRebuild
    extends LiteScope<_WithoutRebuild, _WithoutRebuildState> {
  final Future<String> Function() loadTitle;

  const _WithoutRebuild({required this.loadTitle});

  @override
  Widget buildOnWaiting(BuildContext context) => const SizedBox.shrink();

  @override
  _WithoutRebuildState createState() => _WithoutRebuildState();
}

final class _WithoutRebuildState
    extends LiteScopeState<_WithoutRebuild, _WithoutRebuildState> {
  late String _title;

  @override
  Future<void> initStateAsync() async => _title = await params.loadTitle();

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    return Text(_title);
  }
}

final class TitleScope extends LiteScope<TitleScope, TitleScopeState> {
  final Future<String> Function() loadTitle;

  const TitleScope({super.key, required this.loadTitle});

  @override
  Widget buildOnWaiting(BuildContext context) => const SizedBox.shrink();

  @override
  TitleScopeState createState() => TitleScopeState();
}

final class TitleScopeState
    extends LiteScopeState<TitleScope, TitleScopeState> {
  late String _title;

  @override
  Future<void> initStateAsync() async => _title = await params.loadTitle();

  @override
  void onInitialized() => setState(() {});

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    return Text(_title);
  }
}
