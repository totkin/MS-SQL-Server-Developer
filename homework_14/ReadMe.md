## Домашнее задание 14
*Создаем CLR*

мар'24
<hr>

### Структура каталога

```
homework_14
├── OTUS2024       - репозиторий с dll (проект MS Visual Studio)
├── ReadMe.md      - Данный файл
└── HW14.sql       - Реализация в MS SQL

```

<hr>

Домашнее задание [SQL](HW14.sql)

Реализация на базе примера [Microsoft](https://learn.microsoft.com/ru-ru/sql/relational-databases/clr-integration-database-objects-user-defined-functions/clr-table-valued-functions?view=sql-server-ver16) с небольшой доработкой под контекст WideWorldImporters


<hr>

### Описание ДЗ

**Цель:**
В этом ДЗ вы научитесь создавать CLR.

**Описание/Пошаговая инструкция выполнения домашнего задания:**

Варианты ДЗ (сделать любой один):

Взять готовую dll, подключить ее и продемонстрировать использование.
Например, https://sqlsharp.com
Взять готовые исходники из какой-нибудь статьи, скомпилировать, подключить dll, продемонстрировать использование.
Например,
https://www.sqlservercentral.com/articles/xlsexport-a-clr-procedure-to-export-proc-results-to-excel
https://www.mssqltips.com/sqlservertip/1344/clr-string-sort-function-in-sql-server/
https://habr.com/ru/post/88396/
Написать полностью свое (что-то одно):
Тип: JSON с валидацией, IP / MAC - адреса, ...
Функция: работа с JSON, ...
Агрегат: аналог STRING_AGG, ...
(любой ваш вариант)

Результат ДЗ:
- исходники (если они есть), желательно проект Visual Studio
- откомпилированная сборка dll
- скрипт подключения dll
- демонстрация использования

<hr>

**Критерии оценки:** Статус "Принято" ставится, если выполнен один из вариантов заданий и продемонстрировано использование созданных CLR-объектов.
