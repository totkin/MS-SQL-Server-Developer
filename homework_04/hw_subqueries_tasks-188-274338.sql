/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

-- WITH
----------------------------------------------------------------

WITH SP(SalespersonPersonID) AS(
SELECT distinct SalespersonPersonID
FROM Sales.Invoices as SI
WHERE InvoiceDate='2015-07-04'
)

select PP.FullName
from Application.People as PP
	 left outer join  SP on PP.PersonID=SP.SalespersonPersonID
where PP.IsSalesperson = 1 and SP.SalespersonPersonID is null


-- SUB
----------------------------------------------------------------

select FullName
from Application.People as PP
where IsSalesperson = 1
and PersonID
	not in (SELECT distinct SalespersonPersonID
			FROM Sales.Invoices as SI
			WHERE InvoiceDate='2015-07-04')



/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

-- var 1
-------------------------------------------------------------------------------
SELECT DISTINCT
	SI.StockItemID, SI.StockItemName, OL.UnitPrice
FROM
	Sales.OrderLines                AS OL
	INNER JOIN Warehouse.StockItems AS SI ON OL.StockItemID = SI.StockItemID
	INNER JOIN (
		SELECT min(UnitPrice) AS MP
		FROM Sales.OrderLines where isnull(Quantity,0)>0
	)                               AS MP ON OL.UnitPrice=MP.MP


-- var 2
-------------------------------------------------------------------------------
SELECT TOP(1)
	SI.StockItemID, SI.StockItemName,
	(SELECT min(OL.UnitPrice) 
     FROM Sales.OrderLines as OL
	 WHERE SI.StockItemID = OL.StockItemID AND isnull(OL.Quantity,0)>0
	 GROUP BY OL.StockItemID) as UnitPrice
FROM
	Warehouse.StockItems as SI
ORDER BY 3



/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

-- var 1
-------------------------------------------------------------------------------
WITH CI(CustomerID)
AS(
	SELECT TOP(5) CustomerID
	FROM Sales.CustomerTransactions
	ORDER BY TransactionAmount DESC
)

SELECT CC.CustomerID, CC.CustomerName
FROM Sales.Customers AS CC
WHERE  CC.CustomerID in (select CustomerID from CI)
ORDER BY CC.CustomerID, CC.CustomerName


-- var 2
-------------------------------------------------------------------------------
WITH CI(CustomerID)
AS(
	SELECT TOP(5) CustomerID
	FROM Sales.CustomerTransactions
	ORDER BY TransactionAmount DESC
)

SELECT DISTINCT CC.CustomerID, CC.CustomerName
FROM Sales.Customers AS CC INNER JOIN CI ON CC.CustomerID=CI.CustomerID
ORDER BY CC.CustomerID, CC.CustomerName


-- var 3
-------------------------------------------------------------------------------
SELECT DISTINCT CustomerID, CustomerName
FROM (
	SELECT TOP(5)
		CC.CustomerID, CC.CustomerName, CT.TransactionAmount
	FROM Sales.CustomerTransactions AS CT
		 INNER JOIN Sales.Customers AS CC ON CT.CustomerID = CC.CustomerID
	ORDER BY TransactionAmount DESC
) as SOURCE_TABLE
ORDER BY CustomerID, CustomerName


-- var 4
-------------------------------------------------------------------------------
SELECT CustomerID, CustomerName
FROM Sales.Customers
WHERE CustomerID in (
	SELECT DISTINCT CustomerID
		FROM Sales.CustomerTransactions
		WHERE TransactionAmount in (
			SELECT TOP(5) TransactionAmount FROM Sales.CustomerTransactions ORDER BY TransactionAmount DESC
		)
	)
ORDER BY CustomerID, CustomerName


/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

-- var 1
-------------------------------------------------------------------------------
WITH SI(StockItemID)
AS(


-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --
