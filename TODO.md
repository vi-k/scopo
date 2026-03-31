# TODO

- Update README!!!
- Описать все примеры.
- Написать нормальную документацию.
- example для `ScopeWidgetCore`.
- `waitForChildren`, `asyncScopeRoot` - переделать. `asyncScopeRoot` перенести
  логику в `AsyncScopeCoordinator`. timeout перенести внутрь `waitForChildren`.

Тесты:
- одновременно `notifyDependents` и перестроение дерева сверху (`setState`).
- проверить ребёнка с глобальным ключом, что он успешно перерегистрируется и
  фризит старого родителя.
