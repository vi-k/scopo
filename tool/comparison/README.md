# Зонды сравнения scopo с соседями по pub.dev

Одна и та же задача — экрану нужны БД и сессия поверх неё, обе закрываются
асинхронно — на scopo и на пакетах, которые решают её по-своему. Каждый ресурс
пишет журнал, и по журналу видно, что происходит, когда экран уходит посреди
загрузки, пересоздаётся или падает. Из этих журналов взят довод, что нишу
scopo — жизненный цикл ресурса, которым владеет поддерево, — на pub.dev целиком
не закрывает никто.

Зонды написаны агентами двух ревью рынка 2026-10-30 и перенесены сюда без
правок кода, только с переименованием пакетов:
`docs/records/2026-10-30[1]-fable-market-review.md`,
`docs/records/2026-10-30[2]-opus-market-review.md`, сводка —
`docs/records/2026-10-30[3]-market-reviews-report.md`. Журналы и их чтение —
в самих ревью.

## Что где

- `five_scenarios/` — из ревью Opus. Пять сценариев: уход посреди открытия БД,
  пересборка родителем, мгновенное переоткрытие, сбой восстановления сессии,
  порядок закрытия. Варианты: scopo, scopo со `scopeKey`, cobalt_flutter,
  Riverpod с `ref.mounted` и без, get_it + watch_it, depend.
- `refresh_mid_open/` — из ревью Fable. Один сценарий: «обновить» посреди
  открытия БД, то есть пересоздание экрана с новым ключом, и уход. Варианты:
  scopo со `scopeKey`, Riverpod (scoped), get_it + watch_it, yx_scope.

## Как запускать

Закреплённый Flutter 3.38.1 не подходит: Riverpod 3.4.3 требует Dart 3.12.
Ревью гонялись глобальным Flutter 3.47.0, не через `fvm`:

```sh
cd tool/comparison/five_scenarios && flutter pub get && flutter test
cd tool/comparison/refresh_mid_open && flutter pub get && flutter test
```

Оба прогона кончаются одним красным тестом, и это ожидаемо: падает вариант
get_it + watch_it, и падение и есть находка — «not ready yet» и потерянная БД.
`five_scenarios` даёт `+34 -1`, `refresh_mid_open` — `+3 -1` (проверено
2026-10-30).

Своего `.dart_tool` у корня зонды не трогают: у каждого свой пакет. Корневой
`flutter analyze` их пропускает (`analysis_options.yaml`), в архив пакета
`tool/` не входит (`.pubignore`).

## scopo из рабочей копии

В `pubspec.yaml` обоих scopo прибит к 0.21.0 с pub.dev — на нём сняты журналы
ревью. Проверить текущее дерево — положить рядом с `pubspec.yaml`
`pubspec_overrides.yaml` (он вне git) и снова сделать `pub get`:

```yaml
dependency_overrides:
  scopo:
    path: ../../..
```
