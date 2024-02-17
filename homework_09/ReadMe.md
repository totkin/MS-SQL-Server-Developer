## Домашнее задание 09
*XML и JSON*

фев'24
<hr>

### Структура каталога

```
homework_09
├── hw_xml_json_tasks-188-97b45f.sql    - Домашняя работа запросами SQL
├── ReadMe.md                           - Данный файл
└── _work                               - Рабочая папка с материалами /оставлена для своих задач автора/

```

<hr>

[Ссылка на файл с ДЗ09](hw_xml_json_tasks-188-97b45f.sql)
<hr>

### Описание ДЗ

**Цель:**
В этом ДЗ вы научитесь работать с данными и потренируетесь писать запросы XML и JSON.

**Описание/Пошаговая инструкция выполнения домашнего задания:**

В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice
Загрузить эти данные в таблицу Warehouse.StockItems.
Существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName).
Сделать два варианта: с помощью OPENXML и через XQuery.
Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
Примечания к заданиям 1, 2:
Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML.
Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
StockItemID
StockItemName
CountryOfManufacture (из CustomFields)
FirstTag (из поля CustomFields, первое значение из массива Tags)
Найти в StockItems строки, где есть тэг "Vintage".
Вывести:
StockItemID
StockItemName
(опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.

Запрос написать через функции работы с JSON.

Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:

... where ... = 'Vintage'

Так принято не будет:

... where ... Tags like '%Vintage%'

... where ... CustomFields like '%Vintage%'
<hr>

**Критерии оценки:** Статус "Принято" ставится, если написаны SQL-запросы, выводящие правильные результаты в соответствии с заданиями.