import 'manifest.dart';

// A negative probe holds a compile-time refusal no widget test can hold; its
// positive twin differs only in the argument under test, so the expected error
// cannot come from the scaffolding.

/// Imports and declarations the probes lean on.
const contractSupport = '''
import 'package:flutter/widgets.dart';
import 'package:scopo/scopo.dart';

class Profile {
  String get name => 'Ada';
}

class Counter extends ChangeNotifier {}
''';

/// The probes.
const contracts = [
  ContractProbe(
    'contracts/ScopeInitContext.progress(null)',
    'ctx.progress(null);\n',
    DocEnvironment(
      'void example(ScopeInitContext ctx) {',
      '}',
      expectedErrors: _refused,
    ),
  ),
  ContractProbe(
    'contracts/ScopeModel(create: (context) => Profile())',
    'ScopeModel<Profile>(\ncreate: (context) => Profile(),\n',
    _scope,
  ),
  ContractProbe(
    'contracts/ScopeModel(create: null)',
    'ScopeModel<Profile>(\ncreate: null,\n',
    DocEnvironment(_scopeBefore, _scopeAfter, expectedErrors: _refused),
  ),
  ContractProbe(
    'contracts/ScopeNotifier(create: (context) => Counter())',
    'ScopeNotifier<Counter>(\ncreate: (context) => Counter(),\n',
    _scope,
  ),
  ContractProbe(
    'contracts/ScopeNotifier(create: null)',
    'ScopeNotifier<Counter>(\ncreate: null,\n',
    DocEnvironment(_scopeBefore, _scopeAfter, expectedErrors: _refused),
  ),
];

const _refused = ['argument_type_not_assignable'];
const _scopeBefore = 'Widget example() {\nreturn ';
const _scopeAfter = 'dispose: (model) {},\n'
    'builder: (context) => const SizedBox(),\n);\n}';
const _scope = DocEnvironment(_scopeBefore, _scopeAfter);
