import 'manifest.dart';

/// The blocks of the `utils` topic.
const utilsTopic = DocManifest(
  'doc/utils.md',
  support: _support,
  {
    'listening-to-a-listenable/final-subscription-counter-lis': _body,
    'listening-to-a-listenable/final-subscription-model-selec': _body,
    'listening-to-a-listenable/listenableselector-counter-int': _body,
    'progressiterator/final-progress-progressiterato': _body,
    'screenshotreplacer/screenshotreplacer': _body,
  },
);

const _body = DocEnvironment('void example() {', '}');
const _support = '''
import 'package:flutter/widgets.dart';
import 'package:scopo/listenable.dart';
import 'package:scopo/scopo.dart';

class Counter extends ChangeNotifier {
  int get value => 0;
}

class UserModel extends ChangeNotifier {
  String get userName => 'Ada';
}

final counter = Counter();
final model = UserModel();

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
''';
