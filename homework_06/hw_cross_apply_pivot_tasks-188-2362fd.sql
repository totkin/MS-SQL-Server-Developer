/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/


-- прототипирование на group by

select 
	replace(replace([CustomerName],'Tailspin Toys (',''),')','') as [клиент уточнение],
	dateadd(day,1,eomonth(SI.InvoiceDate,-1)) as [InvoiceMonth],
	count(distinct SI.InvoiceID)
from
	Sales.Invoices                AS SI
	INNER JOIN Sales.InvoiceLines AS IL ON SI.InvoiceID = IL.InvoiceID
	INNER JOIN Sales.Customers    AS CC ON SI.CustomerID = CC.CustomerID
where CC.CustomerID between 2 and 6
group by replace(replace([CustomerName],'Tailspin Toys (',''),')',''),
	dateadd(day,1,eomonth(SI.InvoiceDate,-1))



-- pivot

SELECT 
  *
  ---- вариант с детальным списком столбцов, но в простой сборке (присутсвуют только нужные столбцы и порядок столбцов не важен) можно не заморачиваться
  --[InvoiceMonth], [Gasport, NY],[Jessie, ND],[Medicine Lodge, KS],[Peeples Valley, AZ],[Sylvanite, MT]  
FROM
(
	select
		replace(replace([CustomerName],'Tailspin Toys (',''),')','') as [клиент уточнение],
		dateadd(day,1,eomonth(SI.InvoiceDate,-1)) as [InvoiceMonth],
		SI.InvoiceID
	from
		Sales.Invoices             AS SI
		INNER JOIN Sales.Customers AS CC ON SI.CustomerID = CC.CustomerID
) AS SourceTable  
PIVOT  
(  
  count(InvoiceID)
  FOR [клиент уточнение] IN ([Gasport, NY],[Jessie, ND],[Medicine Lodge, KS],[Peeples Valley, AZ],[Sylvanite, MT])  
) AS PivotTable
order by [InvoiceMonth]



/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/


-- вспомогательный запрос для поиска нужных колонок
SELECT COLUMN_NAME
FROM information_schema.columns
WHERE TABLE_SCHEMA='Sales' AND TABLE_NAME='Customers' AND COLUMN_NAME like '%Addres%'


-- решение задачи
SELECT [CustomerName], [AddressLine] 
FROM [Sales].[Customers]  
UNPIVOT  
   (AddressLine FOR Adresses IN   
      ([DeliveryAddressLine1],[DeliveryAddressLine2],[PostalAddressLine1],[PostalAddressLine2])  
	)AS unpvt
where [CustomerName] like '%Tailspin Toys%'
order by  [CustomerName], [AddressLine] 




/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/


SELECT CountryId, CountryName, Code 
FROM (select
		CountryId, CountryName,[IsoAlpha3Code] as N1,
		cast([IsoNumericCode] as nvarchar(3))  as N2
	   from [Application].[Countries]
	  ) as CC
UNPIVOT  
	(Code FOR IsoCodes IN (N1,N2)) AS unpvt
ORDER BY CountryName, Code 


/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT
	CC.CustomerID, CC.CustomerName,[StockItemID],[UnitPrice],[InvoiceDate]
FROM [Sales].[Customers] as CC
OUTER APPLY -- на всякий случай OUTER
(SELECT TOP 2 
	[StockItemID],[UnitPrice],max([IS].[InvoiceDate]) as [InvoiceDate]
	FROM
		Sales.Invoices                 AS [IS]
		INNER JOIN Sales.InvoiceLines  AS IL ON [IS].InvoiceID = IL.InvoiceID
	WHERE [IS].[CustomerID]=CC.CustomerID
	group by [StockItemID],[UnitPrice]
	order by [UnitPrice] desc
	) as DD
order by CC.CustomerID, CC.CustomerName,[UnitPrice] desc
