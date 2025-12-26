import 'package:flutter/material.dart';
import 'package:scopo/scopo.dart';

class ScopeStateBuilderExample1 extends StatelessWidget {
  const ScopeStateBuilderExample1({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: MyScope());
  }
}

sealed class MyScopeState {
  const MyScopeState();
}

final class MyScopeInitial extends MyScopeState {
  const MyScopeInitial();
}

final class MyScopeInProgress extends MyScopeState {
  const MyScopeInProgress();
}

final class MyScopeSuccess extends MyScopeState {
  const MyScopeSuccess();
}

final class MyScopeFailure extends MyScopeState {
  const MyScopeFailure();
}

final class MyScope extends ScopeStateBuilderBase<MyScope, MyScopeState> {
  const MyScope({super.key}) : super(initialState: const MyScopeInitial());

  static MyScopeState stateOf(BuildContext context, {bool listen = true}) =>
      ScopeStateBuilderBase.stateOf<MyScope, MyScopeState>(
        context,
        listen: listen,
      );

  @override
  Widget build(BuildContext context, ScopeStateNotifier<MyScopeState> model) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [
          Expanded(
            child: switch (model.state) {
              MyScopeInitial() => const _Initial(),
              MyScopeInProgress() => const _InProgress(),
              MyScopeSuccess() => const _Success(),
              MyScopeFailure() => const _Failure(),
            },
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _MyScopeStateChanger(
                title: 'initial',
                doChange: () {
                  model.update(const MyScopeInitial());
                },
              ),
              _MyScopeStateChanger(
                title: 'in progress',
                doChange: () {
                  model.update(const MyScopeInProgress());
                },
              ),
              _MyScopeStateChanger(
                title: 'success',
                doChange: () {
                  model.update(const MyScopeSuccess());
                },
              ),
              _MyScopeStateChanger(
                title: 'failure',
                doChange: () {
                  model.update(const MyScopeFailure());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Icon(Icons.lock_clock));
  }
}

class _InProgress extends StatelessWidget {
  const _InProgress();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _Success extends StatelessWidget {
  const _Success();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('success'));
  }
}

class _Failure extends StatelessWidget {
  const _Failure();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'failure',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

class _MyScopeStateChanger extends StatelessWidget {
  final String title;
  final void Function() doChange;

  const _MyScopeStateChanger({required this.title, required this.doChange});

  @override
  Widget build(BuildContext context) {
    return FilledButton(onPressed: doChange, child: Text(title));
  }
}
