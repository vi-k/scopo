# TODO

- Example: ScopeModel on State + Listenable
- В State добавить initAsync и disposeAsync. Возможно ли?
- LiteScope - скоуп без инициализации и диспоуза зависимостей.
- Добавить buildOnClosing, заменить текущую реализацию
- ScopeState -> ScopeContent

План scopo_demo:

Common
ScopeWidget
ScopeModel
ScopeNotifier
ScopeStateBuilder
ScopeAsyncInitializer
ScopeStreamInitializer
Scope

Common:
Пример счётчика: dialog, modal bottom sheet, non modal bottom sheet, another
screen (+NavigationNode), clone this scope

Этот пример демонстрирует работу скоупа на примере счётчика. Данные счётчика
доступны внутри скоупа в любом виджете, в том числе в диалогах, боттом
шитах и других окнах.

README

Пакет, предоставляющий набор инструментов для создания и управления скоупами на
Flutter. В том числе для внедрения зависимостей, асинхронной инициализации и
асинхронной утилизации.
