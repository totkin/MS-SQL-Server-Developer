/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

select StockItemID,StockItemName
from Warehouse.StockItems
where StockItemName like '%urgent%' or StockItemName like  'Animal%'


/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

select PS.SupplierID,PS.SupplierName
from  Purchasing.Suppliers                      as PS		
	  left outer join Purchasing.PurchaseOrders as PPO on PS.SupplierID=PPO.SupplierID
where PPO.SupplierID is null
group by PS.SupplierID,PS.SupplierName


/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/


DECLARE @OFF BIGINT=1000, @FETCH BIGINT=100

-- вариант TOP WITH TIES https://learn.microsoft.com/ru-ru/sql/t-sql/queries/top-transact-sql?view=sql-server-ver16

SELECT
	OO.OrderID,
	FORMAT(OO.OrderDate,'dd.MM.yyyy')      AS OrderDate,
	FORMAT(OO.OrderDate,'MMMM','ru-RU')    AS [название месяца, в котором был сделан заказ],
	DATEPART(QUARTER, OO.OrderDate)        AS [номер квартала, в котором был сделан заказ],
	CASE WHEN MONTH(OO.OrderDate)<5 THEN 1
		 WHEN MONTH(OO.OrderDate)<9 THEN 2
		 ELSE 3 END                        AS [треть года, к которой относится дата заказа],
	CC.CustomerName    
FROM
	Sales.OrderLines           AS OL
	INNER JOIN Sales.Orders    AS OO ON OL.OrderID = OO.OrderID
	INNER JOIN Sales.Customers AS CC ON OO.CustomerID = CC.CustomerID
WHERE (OL.UnitPrice>100 or OL.Quantity>20) AND OO.[PickingCompletedWhen] IS NOT NULL
GROUP BY OO.OrderID,OO.OrderDate,CC.CustomerName
ORDER BY 4,5,OO.OrderDate --по номерам, конечно, не очень правильно, но тут короче
	OFFSET @OFF ROWS
    FETCH NEXT @FETCH ROWS ONLY


/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT DISTINCT
	PO.PurchaseOrderID,     --тут вариант оставил, если ID не нужно, можно закомментить строку и более поятно сработает DISTINCT
	DM.DeliveryMethodName   AS [способ доставки],
	PO.ExpectedDeliveryDate AS [дата доставки],
	SS.SupplierName         AS [имя поставщика],
	PP.FullName             AS [имя контактного лица принимавшего заказ]  
FROM
	Purchasing.Suppliers                   AS SS
	INNER JOIN Purchasing.PurchaseOrders   AS PO ON SS.SupplierID = PO.SupplierID
	INNER JOIN Application.People          AS PP ON PO.ContactPersonID = PP.PersonID
	INNER JOIN Application.DeliveryMethods AS DM ON PO.DeliveryMethodID = DM.DeliveryMethodID
WHERE
	YEAR(PO.ExpectedDeliveryDate)*100 + MONTH(PO.ExpectedDeliveryDate)=201301 -- вариант -- PO.ExpectedDeliveryDate between '20130101' and '20130131'
	AND DM.DeliveryMethodName in (N'Air Freight' , N'Refrigerated Air Freight')
	AND PO.IsOrderFinalized=1


/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP(10)
	OO.OrderID,
	PP.FullName,
	CC.CustomerName
FROM
	Sales.Orders                  AS OO
	INNER JOIN Application.People AS PP ON OO.SalespersonPersonID = PP.PersonID
	INNER JOIN Sales.Customers    AS CC ON OO.CustomerID = CC.CustomerID
ORDER BY OO.OrderDate DESC


/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

-- Упрощенный вариант: имена клиентов=CustomerName, а не имена сотрудников клиентов
-- Сделана доп проверка на объем покупки больше 0

SELECT CC.CustomerID, CC.CustomerName, CC.PhoneNumber
FROM
	Sales.Orders                     AS OO
	INNER JOIN Sales.Customers       AS CC ON OO.CustomerID = CC.CustomerID
	INNER JOIN Sales.OrderLines      AS OL ON OO.OrderID = OL.OrderID
	INNER JOIN  Warehouse.StockItems AS SI ON OL.StockItemID = SI.StockItemID
WHERE SI.StockItemName = N'Chocolate frogs 250g'
GROUP BY CC.CustomerID,	CC.CustomerName, CC.PhoneNumber
HAVING SUM(OL.Quantity)>0
ORDER BY CC.CustomerID, CC.CustomerName, CC.PhoneNumber
