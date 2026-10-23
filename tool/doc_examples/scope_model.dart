import 'manifest.dart';

/// The blocks of the `ScopeModel` topic.
const scopeModel = DocManifest(
  'doc/scope_model.md',
  support: _support,
  {
    'the-three-levels/scopemodel-cart': _body,
    'the-three-levels/create-context': DocEnvironment(
      'void example() {\nScopeModel<Session>(',
      'dispose: (session) {},\n'
          'builder: (context) => const SizedBox.shrink(),\n);\n}',
    ),
    'the-three-levels/scopemodel-value-value-cart-bu': _body,
    'the-three-levels/final-cart-scopemodel-of-cart-': _body,
    'the-three-levels/CartScope': DocEnvironment('', ''),
    'what-notifies-whom/scopemodel-value-value-cart-bu': _body,
  },
);

const _body = DocEnvironment('void example(BuildContext context) {', '}');
const _support = '''
import 'package:flutter/widgets.dart';
import 'package:scopo/scopo.dart';

class Cart {
  int get total => 0;
  void close() {}
}

final cart = Cart();

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class Channel {
  static Channel open() => Channel();
  void close() {}
}

class Store {
  static Store open() => Store();
}

class Session {
  Session(Channel channel, Store store);
}
''';
