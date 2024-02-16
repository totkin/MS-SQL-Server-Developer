/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/


-- вариант с табличной переменной
---------------------------------------------------------------------------------------------------------
SET STATISTICS TIME ON;

DECLARE @TABLE_OTUS TABLE
      (YM INT null,
       [сумма продажи] DECIMAL(18,3) null
       )

INSERT @TABLE_OTUS (YM,[сумма продажи])
SELECT
	YEAR(SUB_SI.InvoiceDate)*100+MONTH(SUB_SI.InvoiceDate) AS YM,
	SUM(SUB_IL.UnitPrice * SUB_IL.Quantity)                AS [сумма продажи]
FROM Sales.Invoices                 AS SUB_SI
	 INNER JOIN Sales.InvoiceLines  AS SUB_IL ON SUB_SI.InvoiceID = SUB_IL.InvoiceID
GROUP BY YEAR(SUB_SI.InvoiceDate)*100+MONTH(SUB_SI.InvoiceDate)
ORDER BY 1

SELECT
	SI.InvoiceID as [id продажи],
	CC.CustomerName as [название клиента],
	SI.InvoiceDate as [дата продажи],
	SUM(IL.UnitPrice * IL.Quantity) AS [сумма продажи],
	(SELECT SUM([сумма продажи]) FROM @TABLE_OTUS WHERE YM<=YEAR(SI.InvoiceDate)*100+MONTH(SI.InvoiceDate)) AS [сумма нарастающим итогом]
FROM
	Sales.Invoices                AS SI
	INNER JOIN Sales.InvoiceLines AS IL ON SI.InvoiceID = IL.InvoiceID
	INNER JOIN Sales.Customers    AS CC ON SI.CustomerID = CC.CustomerID	
GROUP BY SI.InvoiceID,CC.CustomerName,SI.InvoiceDate

SET STATISTICS TIME OFF; 

/* ------------------------------------------------------- вывод

 SQL Server Execution Times:
   CPU time = 60 ms,  elapsed time = 62 ms.

(41 rows affected)

(70510 rows affected)

 SQL Server Execution Times:
   CPU time = 982 ms,  elapsed time = 1011 ms.

Completion time: 2024-02-17T00:09:50.3644387+03:00

---------------------------------------------------------- вывод */



/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

SET STATISTICS TIME ON;

SELECT
	SI.InvoiceID as [id продажи],
	CC.CustomerName as [название клиента],
	SI.InvoiceDate as [дата продажи],
	SUM(IL.UnitPrice * IL.Quantity) AS [сумма продажи],
	SUM(SUM(IL.UnitPrice * IL.Quantity))
		over(order by year(SI.InvoiceDate)*100+month(SI.InvoiceDate)
			 ) as  [сумма нарастающим итогом]
FROM
	Sales.Invoices                AS SI
	INNER JOIN Sales.InvoiceLines AS IL ON SI.InvoiceID = IL.InvoiceID
	INNER JOIN Sales.Customers    AS CC ON SI.CustomerID = CC.CustomerID
GROUP BY SI.InvoiceID,CC.CustomerName,SI.InvoiceDate

SET STATISTICS TIME OFF;


/* ------------------------------------------------------- вывод

(70510 rows affected)

 SQL Server Execution Times:
   CPU time = 90 ms,  elapsed time = 105 ms.

Completion time: 2024-02-17T00:10:10.2446136+03:00

---------------------------------------------------------- вывод */



/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

select [month],[rate],StockItemID, StockItemName
from (
	SELECT
		SI.StockItemID, SI.StockItemName, month([IS].InvoiceDate) as [month], sum(IL.Quantity*IL.UnitPrice) as [value],
		DENSE_RANK()over (partition by month([IS].InvoiceDate) order by sum(IL.Quantity*IL.UnitPrice) desc) as rate
	FROM
		Sales.Invoices AS [IS]
		INNER JOIN Sales.InvoiceLines AS IL ON [IS].InvoiceID = IL.InvoiceID
		INNER JOIN Warehouse.StockItems AS SI ON IL.StockItemID = SI.StockItemID
	WHERE year([IS].InvoiceDate)=2016
	GROUP BY SI.StockItemID, SI.StockItemName,month([IS].InvoiceDate)
) as TT
where rate<3
order by [month],[rate]

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/


with ITEMS([StockItemID],[StockItemName],First_Letter, [TypicalWeightPerUnit])
as
(
	select
		[StockItemID],[StockItemName],
		left(replace([StockItemName],'"',''),1) as First_Letter,
		[TypicalWeightPerUnit]
	from [Warehouse].[StockItems]
)

select
	[StockItemID],[StockItemName], 
	DENSE_RANK()over (partition by First_Letter order by [StockItemName])      as [пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново],
	count(*) over()                                                            as [общее количество товаров],
	count(*) over(partition by First_Letter)                                   as [общее количество товаров в зависимости от первой буквы названия товара],
	lead([StockItemID]) over (order by [StockItemName])                        as [следующий id товара исходя из того, что порядок отображения товаров по имени],
	lag([StockItemID]) over (order by [StockItemName])                         as [предыдущий ид товара с тем же порядком отображения (по имени)],
	isnull(lag([StockItemName],2) over (order by [StockItemName]),N'No items') as [названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"],
	ntile(30) over(order by [TypicalWeightPerUnit])                            as [30 групп товаров по полю вес товара на 1 шт]

from ITEMS
order by [StockItemID],[StockItemName]



/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

select PersonID,фамилия,CustomerID, CustomerName,InvoiceDate, [сумма сделки]
from 
(
	SELECT
		PP.PersonID, REPLACE(PP.FullName, PP.PreferredName + ' ', '') AS фамилия,
		CC.CustomerID, CC.CustomerName, 
		[IS].InvoiceDate,
		sum(IL.Quantity*IL.UnitPrice) as [сумма сделки],
		rank() over (partition by PP.PersonID order by [IS].InvoiceDate desc,[IS].InvoiceID desc ) as rate
	FROM 
		Sales.Invoices                 AS [IS]
		INNER JOIN Sales.InvoiceLines  AS IL ON [IS].InvoiceID = IL.InvoiceID
		INNER JOIN Sales.Customers     AS CC ON [IS].CustomerID = CC.CustomerID
		INNER JOIN  Application.People AS PP ON [IS].SalespersonPersonID = PP.PersonID
	GROUP BY PP.PersonID, REPLACE(PP.FullName, PP.PreferredName + ' ', ''),
		CC.CustomerID, CC.CustomerName, 
		[IS].InvoiceDate,[IS].InvoiceID
) as TT where rate=1

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/


select CustomerID, CustomerName, [StockItemID], UnitPrice, InvoiceDate
from 
(
	SELECT
		CC.CustomerID, CC.CustomerName, IL.[StockItemID], IL.UnitPrice,
		max([IS].InvoiceDate) as InvoiceDate,
		rank() over (partition by CC.CustomerID
					 order by IL.UnitPrice desc,
					          sum(IL.Quantity*IL.UnitPrice) desc
					) as rate
	FROM 
		Sales.Invoices                AS [IS]
		INNER JOIN Sales.InvoiceLines AS IL ON [IS].InvoiceID = IL.InvoiceID
		INNER JOIN Sales.Customers    AS CC ON [IS].CustomerID = CC.CustomerID
	group by CC.CustomerID, CC.CustomerName, IL.[StockItemID], IL.UnitPrice
) as TT where rate<3

--Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность.
--НЕ ВЫПОЛНЯЛОСЬ