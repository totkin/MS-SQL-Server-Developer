/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT
	YEAR(II.InvoiceDate)                              as [Год продажи],
	MONTH(II.InvoiceDate)                             as [Месяц продажи],
	AVG(IL.UnitPrice)                                 as [Средняя цена за месяц по всем товарам], 
	SUM(isnull(IL.Quantity,0)*isnull(IL.UnitPrice,0)) as [Общая сумма продаж за месяц]
FROM
	Sales.Invoices                AS II
	INNER JOIN Sales.InvoiceLines AS IL ON II.InvoiceID = IL.InvoiceID
GROUP BY YEAR(II.InvoiceDate),MONTH(II.InvoiceDate)   
ORDER BY 1,2

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/


SELECT
	YEAR(II.InvoiceDate)                              as [Год продажи],
	MONTH(II.InvoiceDate)                             as [Месяц продажи],
	SUM(isnull(IL.Quantity,0)*isnull(IL.UnitPrice,0)) as [Общая сумма продаж за месяц]
FROM
	Sales.Invoices                AS II
	INNER JOIN Sales.InvoiceLines AS IL ON II.InvoiceID = IL.InvoiceID
GROUP BY YEAR(II.InvoiceDate),MONTH(II.InvoiceDate)
HAVING SUM(isnull(IL.Quantity,0)*isnull(IL.UnitPrice,0))>4600000
ORDER BY 1,2


/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT
	YEAR(II.InvoiceDate)                              as [Год продажи],
	MONTH(II.InvoiceDate)                             as [Месяц продажи],
	SI.StockItemName                                  as [Наименование товара],
	SUM(isnull(IL.Quantity,0)*isnull(IL.UnitPrice,0)) as [Общая сумма продаж за месяц],
	MIN(II.InvoiceDate)                               as [Дата первой продажи],
	SUM(isnull(IL.Quantity,0))                        as [Количество проданного]
FROM
	Sales.Invoices                  AS II
	INNER JOIN Sales.InvoiceLines   AS IL ON II.InvoiceID = IL.InvoiceID
	INNER JOIN Warehouse.StockItems AS SI ON IL.StockItemID = SI.StockItemID
GROUP BY YEAR(II.InvoiceDate),MONTH(II.InvoiceDate),SI.StockItemName
HAVING SUM(isnull(IL.Quantity,0))>50
ORDER BY 1,2,3

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/

SELECT
	YEAR(II.InvoiceDate)                              AS [Год продажи],
	MONTH(II.InvoiceDate)                             AS [Месяц продажи],
	CASE WHEN SUM(isnull(IL.Quantity,0)*isnull(IL.UnitPrice,0))>4600000
	     THEN SUM(isnull(IL.Quantity,0)*isnull(IL.UnitPrice,0))
	     ELSE 0 END                                   AS [Общая сумма продаж за месяц]
FROM
	Sales.Invoices                AS II  
	INNER JOIN Sales.InvoiceLines AS IL ON II.InvoiceID = IL.InvoiceID
GROUP BY YEAR(II.InvoiceDate),MONTH(II.InvoiceDate)
ORDER BY 1,2
