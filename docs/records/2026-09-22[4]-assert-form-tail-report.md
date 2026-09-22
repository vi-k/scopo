# Хвост формы отказа: последние четыре ассерта, адресованных читателю

> **Состояние на 2026-09-22:** сделано и смержено, `77ea78a`.
> **Что это:** перевод оставшихся ассертов-«ты передал не то» на
> `FlutterError.fromParts` — и разбор того, что пятым пунктом в списке стоял
> не ассерт.
> **Связанные записи:**
> `2026-09-22[2]-assert-error-form-report.md` (решение о форме и первые три
> места; список «кандидат на следующую мелкую волну» — оттуда),
> `2026-09-22[1]-subscription-boundary-report.md`,
> `2026-09-22[3]-lazy-registration-report.md`.

## Повод

Владелец: «давай сделаем оставшееся». Оставшееся — это список из
`docs/handoff.md`: четыре ассерта, всё ещё написанных длинным текстом одной
строкой, — `ScopeTimeout.none` в `initCancellationTimeout`, он же
в `pauseAfterInitialization`, «контроллер уже использован» и второй `init()`
листа.

## Список оказался неточен: четыре места, но не те

Три первых — ассерты, и они переписаны. **Четвёртый — не ассерт.** Второй
`init()` листа отвергается `StateError`, который летит и в release
(`scope_dependency_mixin.dart`, `'$wrappedName is initializing right now…'`);
такой же формы отказы стоят у контейнера (`scope_auto_dependency.dart`, второй
`init()` и `dispose()` во время инициализации). Переписать их в `FlutterError`
значит сменить тип, который потребитель ловит в работающем приложении, —
ломающая правка ради формы текста. Оставлены как есть.

Единственный настоящий ассерт в `scope_dependency_mixin.dart` — голый
`assert(_state is ScopeDependencyInitial)` в `init()`, вовсе без текста.
Он **не достижим из кода потребителя**, и это замерено, а не выведено: группа
инициализирует только тех детей, у кого `initializationRequired`, то есть чьё
состояние `ScopeDependencyInitial`.

```
PROBE same-twice: no error      runs=1  state=initialized
PROBE first:      no error      runs=1  state=initialized
PROBE second:     no error      runs=1  state=no disposal required
```

Первая проба — один и тот же лист дважды в одном дереве
(`sequential('', [leaf, leaf])`), вторая — лист, закешированный в `late final`
контейнера и попавший во второй `init()` после полного разбора. В обоих
случаях инициализатор отработал **один** раз, ассерт не сработал, и никто
ничего не сказал. Первое — правильное поведение; второе записано
в `docs/handoff.md` как наблюдение: повторно поданный лист тихо не
инициализируется. Объём не расширялся.

На освободившееся четвёртое место встало место, которого в списке не было:
**отрицательный предел в `resolveTimeout`** (`_negativeLimit`,
`scope_timeout.dart`). Через него проходит каждый предел, который пакет ставит
на таймер, текст у него ровно такой же длинный и адресован тому же читателю —
тому, кто посчитал `ScopeTimeout.none + d` и потерял маркер.

## Что теперь говорит каждое из четырёх

| место | заголовок |
| --- | --- |
| `resolveTimeout` | `A timeout of <value> is negative.` |
| `resolveCancellationTimeout` | `ScopeTimeout.none is not accepted by initCancellationTimeout.` |
| `_settleInit` | `pauseAfterInitialization does not accept ScopeTimeout.none or any other negative Duration.` |
| `initDataAsync` | `<Element>.createController handed over a <C> that has already been used.` |

Абзац, который раньше был всем сообщением, разложен под заголовком на
`ErrorDescription` (почему так) и `ErrorHint` (что делать вместо). У паузы
внизу стоит `describeElement('The scope that was given one was')` — у двух
верхних элемента нет вовсе (это функции разрешения предела), а у контроллера
имя элемента уже стоит в самом заголовке, вторым разом его не называют.

Заголовок паузы намеренно не повторяет прежний зачин «`ScopeTimeout.none` is
not accepted by…»: ассерт ловит **любой** отрицательный `Duration`, и
заголовок, называющий причиной маркер, был бы неверен для того, кто передал
`Duration(seconds: -1)` руками. Сам переданный `Duration` назван отдельной
строкой ниже — `The value it was given was …`; у маркера `toString()` печатает
`no timeout`, и это тот самый случай, ради которого он у `_NoTimeout` и
переопределён.

## Нагруженность

Тесты переписаны **до** правки кода — на заголовок, а не на подстроку, — и
все четыре упали на старом коде:

| тест | что сказал старый код |
| --- | --- |
| `a Duration that lost the marker is refused, not run at once` | `_AssertionError` вместо `FlutterError` |
| `ScopeTimeout.none is refused by initCancellationTimeout` | `is not an instance of 'FlutterError'` |
| `ScopeTimeout.none is refused by pauseAfterInitialization` | в событии наблюдателя нет заголовка сразу за именем фазы |
| `refuses a controller that has already been through it` | первая строка ветки ошибки — не заголовок, а начало абзаца |

После правки — 546 зелёных. Два теста из четырёх сверяют
`diagnostics.first` точным совпадением (там ошибка доходит объектом), два
смотрят на текст: у паузы — что заголовок стоит **сразу** за именем фазы
в строке наблюдателя, у контроллера — что заголовком кончается **первая
строка** того, что показано в ветке ошибки. Обе формы ловят и возврат к голому
ассерту, и размывание заголовка в общий текст.

## Что осталось голой строкой — и почему это правильно

Ассерты, которые остались короткими сообщениями, адресованы либо самому
пакету (`'Entry is not attached to this queue'`, `'A wait cannot be bounded
by $limit'`, `` '`aspect` must be …' ``), либо читателю, но одним фактом
и без объяснений (`'The dependency name cannot be empty'`,
`'total ($total) cannot be negative'` у `ProgressIterator`). Форма
`FlutterError.fromParts` нужна там, где под заголовком есть что разложить:
у факта в шесть слов заголовок — это и есть всё сообщение.
