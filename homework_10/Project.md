## Краткое описание проекта
*фев-мар 2024*

<hr>

#### Идея: Прототип работ полного цикла
- загрузка внешних данных единым плоским файлом (csv | xlsx) при помощи пакета SSIS через job (ручной запуск). Ожидаемое кол-во строк в одной поставке <10 тыс.
- разбор данных на справочники и факты на стороне БД средствами sql. Данные грязные, с высокой вероятностью 3-5 раз поменятся подход к интепретации.
- разработка куба средствами SSAS (tabular режим, топология звезда, 3 справочника и 1 таблица фактов, не более 30 аддитивных мер)
- одно представление (openrowset | linked server) к кубу SQL->SSAS с простой выборкой. 

#### Структура данных
- таблица товаров (не более 20 свойств, кол-во записей <5 тыс);
- таблица торговых точек (не более 5 свойств, кол-во записей <100);
- таблица фактов (грануляция по времени - день, кол-во записей <1 млн);
- таблица периодов - автогенерация на стороне SSAS.

#### Простейший макет структуры данных
![schema.png](src%2Fschema.png)