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

USE WideWorldImporters

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/


CREATE FUNCTION SALES.GET_MOST_CUSTOMER
(
	@FirstDate Date    = cast(CURRENT_TIMESTAMP - 10 as DATE) ,   -- Начало периода
	@LastDate Date     = CURRENT_TIMESTAMP                    ,   -- Конец периода
	@OffsetInDays int  = 10,                                      -- Кол-во дней, если не указана одна из границ
	@DEBUG_MODE int    = 0                       -- Режим отладки: 0 - основной режим, <>0 - режим отладки
)
RETURNS NVARCHAR                                 -- Возвращает CustomerName Клиента с наибольшей суммой покупки в указанном временном периоде

AS
BEGIN

	DECLARE @ResultVar NVARCHAR(100)

	IF @DEBUG_MODE = 0
	BEGIN

		IF @FirstDate is null and @LastDate is null and @OffsetInDays is null
		BEGIN
			-- Если все пусто, берем последние 10 дней
			@FirstDate Date = CURRENT_TIMESTAMP-10
			@LastDate Date  = CURRENT_TIMESTAMP
		END

		IF @FirstDate is null and @LastDate is null
			RAISERROR ( 'Обе даты не могут быть пустыми',1,1)

		IF @FirstDate is null and @LastDate is null
			RAISERROR ( 'Обе даты не могут быть пустыми',1,1) 

		IF @FirstDate is null
			BEGIN
			

			END
	
	END

	IF @DEBUG_MODE <> 0
	BEGIN
		SET @ResultVar = NULL
		PRINT 'Debug mode'
		PRINT 'Функция GET_MOST_CUSTOMER возвращает CustomerName Клиента с наибольшей суммой покупки в указанном временном периоде'
		PRINT 'Тут можно вставить разный полезный текст'
		PRINT 'Например, иногда удобно получить полный текст запроса(или запросов), который используется'
		PRINT 'Или примеры запуска, максимально приближенные к задачам бизнеса'

	END


	RETURN @ResultVar

END
GO



/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

напишите здесь свое решение

/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/

напишите здесь свое решение

/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/

напишите здесь свое решение

