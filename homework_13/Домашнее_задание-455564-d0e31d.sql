/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "18 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE [WideWorldImporters]
GO;

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/


CREATE OR ALTER FUNCTION [Sales].[GET_MOST_CUSTOMER](
    @FirstDate    DATE = NULL,  -- Start of the period
    @LastDate     DATE = NULL   -- End of the period
)
RETURNS NVARCHAR(100)           -- Returns the CustomerName of the customer with the highest sum
AS
BEGIN
    DECLARE @ResultVar    NVARCHAR(100)
	DECLARE @TempDate     DATE = '2013-01-20' -- any default date -- CAST(CURRENT_TIMESTAMP AS DATE)
	DECLARE @DayIncrement int  = 10           -- default day increment

	IF @FirstDate IS NULL AND @LastDate IS NULL
	BEGIN
		SET @LastDate  = CAST(@TempDate as date)
		SET @FirstDate = DATEADD(day,-@DayIncrement,@LastDate)
	END

	IF @FirstDate IS NULL
		SET @FirstDate = DATEADD(day,-@DayIncrement,@LastDate)
	IF @LastDate IS NULL
		SET @LastDate  = DATEADD(day,@DayIncrement,@FirstDate)

	IF @FirstDate > @LastDate
	BEGIN
		SET @TempDate  = @LastDate
		SET @LastDate  = @FirstDate
		SET @FirstDate = @TempDate
	END

		
	SELECT TOP(1)
		@ResultVar = CC.CustomerName
	FROM
		Sales.Invoices                AS II
		INNER JOIN Sales.InvoiceLines AS IL ON II.InvoiceID  = IL.InvoiceID
		INNER JOIN Sales.Customers    AS CC ON II.CustomerID = CC.CustomerID
	WHERE II.InvoiceDate between @FirstDate AND @LastDate
	GROUP BY CC.CustomerName
	ORDER BY SUM(IL.Quantity* IL.UnitPrice)  DESC

    RETURN @ResultVar
END
GO
-------------------------------------------------------------------------------------------

SELECT
[Sales].[GET_MOST_CUSTOMER] (NULL, NULL)                 as [Test null],
[Sales].[GET_MOST_CUSTOMER] (NULL, '2013-01-10')         as [Test left null],
[Sales].[GET_MOST_CUSTOMER] ('2013-01-10', NULL)         as [Test rigth null],
[Sales].[GET_MOST_CUSTOMER] (default , '2013-03-10')     as [Test default],
[Sales].[GET_MOST_CUSTOMER] ('2013-03-10', '2013-01-10') as [Test revert values],
[Sales].[GET_MOST_CUSTOMER] ('2013-01-10', '2013-03-10') as [Test simple values]
GO;

/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/


CREATE OR ALTER PROCEDURE [Sales].[GetSumByCustomerID]
	@CustomerID INT = 1
AS
BEGIN
    SELECT SUM(IL.Quantity* IL.UnitPrice) as SumByCustomer
	FROM
		Sales.Invoices                AS II
		INNER JOIN Sales.InvoiceLines AS IL ON II.InvoiceID  = IL.InvoiceID
		INNER JOIN Sales.Customers    AS CC ON II.CustomerID = CC.CustomerID
	WHERE CC.CustomerID = @CustomerID
END
GO

/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/

CREATE OR ALTER FUNCTION Sales.GetCustomerInvoicesFunction(@customerId INT)
RETURNS TABLE
AS
RETURN
(
    SELECT TOP(10) II.InvoiceDate, IL.StockItemID, sum(IL.Quantity * IL.UnitPrice) as VAL
    FROM Sales.Invoices           as II
    INNER JOIN Sales.InvoiceLines as IL ON II.InvoiceID = IL.InvoiceID
    WHERE II.CustomerID = @customerId
	GROUP BY II.InvoiceDate, IL.StockItemID
);
GO


CREATE OR ALTER PROCEDURE Sales.GetCustomerInvoicesProcedure
    @customerId INT
AS
BEGIN
    SELECT TOP(10) II.InvoiceDate, IL.StockItemID, sum(IL.Quantity * IL.UnitPrice) as VAL
    FROM Sales.Invoices           as II
    INNER JOIN Sales.InvoiceLines as IL ON II.InvoiceID = IL.InvoiceID
    WHERE II.CustomerID = @customerId
	GROUP BY II.InvoiceDate, IL.StockItemID
END;
GO


declare @i int = 0

while @i<5
BEGIN
	exec Sales.GetCustomerInvoicesProcedure 1 
	set @i=@i+1
END

set @i=0

while @i<5
BEGIN

SELECT * FROM [Sales].[GetCustomerInvoicesFunction](@i)
	set @i=@i+1
END


-- Получаем 49/51


/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/


-- Не уверен, что правильно понял задание.

SELECT TOP 100
CustomerName, InvoiceDate, StockItemID, VAL
FROM [Sales].[Customers]
CROSS APPLY Sales.GetCustomerInvoicesFunction(CustomerId)
ORDER BY CustomerName, InvoiceDate, StockItemID

