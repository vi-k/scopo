# `listen` и `select` на `Listenable` — во второй импорт

> **Состояние на 2026-10-23:** сделано и влито в `main` (`f0a3af6`), выпущено
> в 0.18.0 (`507b965`, тег `v0.18.0`).
> **Что это:** почему расширения `listen` и `select` ушли из
> `package:scopo/scopo.dart` в `package:scopo/listenable.dart` и что осталось
> на месте.
> **Связанные записи:** нет.

## Откуда задача

Сессия solo сообщила о конфликте 2026-10-23 и передала решение владельца,
принятое там же, дословно: «давай перенесём». Вариант «удалить совсем» он
рассмотрел и отверг.

`flutter_solo` во втором импорте `package:flutter_solo/listenable.dart`
объявляет `SoloListen.listen` на `Listenable` и `SoloSelect.select`
на `ValueListenable<S>`. Пакеты друг от друга не зависят, конфликт возникает
в файле, импортирующем оба:

- `listen` — `ambiguous_extension_member_access`: ни одно расширение
  не точнее другого.
- `select` хуже. `ListenableSelectExtension<L extends Listenable> on L`
  подставляет в `L` весь тип получателя и потому точнее расширения
  на `ValueListenable<S>`. Вызов, написанный для `flutter_solo`, молча уходит
  в scopo и падает на сигнатуре: «The getter 'isEven' isn't defined…»
  и «2 positional arguments expected…». Лечилось только `hide` у импорта
  scopo.

`flutter_solo` решил это у себя так же: «They are extensions on the framework's
own `ValueListenable` and `Listenable`… The import is the choice».

## Что сделано

- `lib/listenable.dart` — новая библиотека, экспортирует
  `src/utils/listenable/listen.dart` целиком: `ListenableListenExtension`,
  `ListenableSelectExtension`, `ListenableSubscription`,
  `ListenableSelectSubscription`, `CompositeListenableSubscription`.
  Подписки ушли вместе с расширениями: без расширений получить их нельзя,
  а держать тип результата в одном импорте, а способ его получить в другом —
  бессмысленно.
- `lib/scopo.dart` этот файл больше не экспортирует, на его месте комментарий
  с причиной.
- `ListenableSelector`, `ListenableView`, `StateAsNotifier` остаются в главном
  импорте: это классы и миксин, с расширениями они не сталкиваются.
  `ListenableSelector` зовёт `select` через `src` напрямую.
- `test/listenable_import_test.dart` объявляет два расширения по образцу
  `flutter_solo` и импортирует только `scopo.dart`. До правки файл
  не собирался ровно с теми ошибками, что прислала solo; после — три теста
  зелёные.
- Импорт `package:scopo/listenable.dart` добавлен в
  `test/listenable_utils_test.dart`, в `console_view.dart` демо и в подложку
  стенда `tool/doc_examples/utils.dart`. Других потребителей анализатор
  не нашёл. Упоминания `select` в `doc/base.md`, `test/ide/*`
  и `example/minimal` — это `select` скоупов (`App.select(context, …)`),
  правка их не касается.
- `doc/utils.md` и README (раздел Installation) говорят о втором импорте
  и о том, зачем он нужен; зеркала обновлены. В `CHANGELOG.md` открыт раздел
  0.18.0 со строкой **Breaking**.

## Чего не делали

Имя `listenable.dart` взято по образцу `flutter_solo`. Файл, которому нужны
расширения обоих пакетов, по-прежнему ставит `hide` у одного из импортов, —
это и есть «the import is the choice», а не дефект.
