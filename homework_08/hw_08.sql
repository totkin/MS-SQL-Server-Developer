/*
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
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers
*/


--------------------------------------------
-- Анализ таблицы + техническая разметка  --
--------------------------------------------

DECLARE @max_length int=35

SELECT
	CC.COLUMN_NAME, CC.COLUMN_DEFAULT, CC.IS_NULLABLE, CC.DATA_TYPE, TC.CONSTRAINT_TYPE
	
	-- для простоты работаем только с полями без дефолтных значенией, без GENERATED ALWAYS и с обязательным заполнением
	-- GENERATED ALWAYS ловим примерно так (тут не учтена схема в явном виде!):
	--		SELECT OBJECT_NAME(CC.object_id), CC.name
    --		FROM sys.all_columns as CC inner join sys.all_objects as OO on CC.object_id=OO.object_id and OBJECT_NAME(CC.object_id)='Customers' AND [generated_always_type_desc]<>'NOT_APPLICABLE'

	, case when (CC.COLUMN_DEFAULT is null) AND (CC.IS_NULLABLE='NO') AND CC.COLUMN_NAME not in ('ValidFrom','ValidTo')
	       then
			QUOTENAME(CC.COLUMN_NAME) + N','
			  + replicate('-',@max_length-len(CC.COLUMN_NAME))
			  + isnull(TC.CONSTRAINT_TYPE + '-','')
			  + CC.DATA_TYPE + isnull('(' + CAST(CC.CHARACTER_MAXIMUM_LENGTH AS NVARCHAR(3)) + ')','')
			else '' end
	  as [Fileds_List]
	, case when (CC.COLUMN_DEFAULT is null) AND (CC.IS_NULLABLE='NO') AND CC.COLUMN_NAME not in ('ValidFrom','ValidTo')
	       then
				case CC.DATA_TYPE 
				-- рандомизатор с примитивным учётом типа
				when 'int'        then 'ABS(CHECKSUM(NEWID()) % 10)'        -- ID до 10 скорее всего встретятся в справочниках
				when 'bit'        then '1'
				when 'decimal'    then 'cast(RAND()*1000 as decimal(18,2))' -- по наиболее часто встретившемуся варианту
				when 'date'       then 'CAST(CURRENT_TIMESTAMP AS DATE)' 
				when 'datetime2'  then 'CURRENT_TIMESTAMP'
				when 'nvarchar'   then 'LEFT(CONVERT(varchar(255), NEWID()),' +  CAST(CC.CHARACTER_MAXIMUM_LENGTH AS NVARCHAR(3)) +')'
				else '--need value--' end + ','
			else '' end
	  as [Rand_Values_List]
FROM
	INFORMATION_SCHEMA.TABLE_CONSTRAINTS                        AS TC
	RIGHT OUTER JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE AS CCU ON TC.CONSTRAINT_NAME = CCU.CONSTRAINT_NAME
	RIGHT OUTER JOIN INFORMATION_SCHEMA.COLUMNS                 AS CC  ON CCU.TABLE_CATALOG = CC.TABLE_CATALOG
																		 AND CCU.TABLE_SCHEMA = CC.TABLE_SCHEMA
																		 AND CCU.TABLE_NAME = CC.TABLE_NAME
																		 AND CCU.COLUMN_NAME = CC.COLUMN_NAME
WHERE CC.TABLE_NAME = N'Customers' AND CC.TABLE_SCHEMA='Sales'
ORDER BY
	case TC.CONSTRAINT_TYPE when 'PRIMARY KEY' then 1
							when 'FOREIGN KEY' then 2
							when 'UNIQUE'      then 3
	else 4 end,
	CC.DATA_TYPE,CC.ORDINAL_POSITION



--------------------------------------------
-- Заполнение 5 записями                  --
--------------------------------------------

SET XACT_ABORT, NOCOUNT ON

DECLARE @iter int=0

WHILE @iter<5
BEGIN
	BEGIN TRY  

		INSERT INTO [Sales].[Customers]
		(
			[BillToCustomerID],-------------------FOREIGN KEY-int
			[CustomerCategoryID],-----------------FOREIGN KEY-int
			[PrimaryContactPersonID],-------------FOREIGN KEY-int
			[DeliveryMethodID],-------------------FOREIGN KEY-int
			[DeliveryCityID],---------------------FOREIGN KEY-int
			[PostalCityID],-----------------------FOREIGN KEY-int
			[LastEditedBy],-----------------------FOREIGN KEY-int
			[CustomerName],-----------------------UNIQUE-nvarchar-100
			[IsStatementSent],--------------------bit
			[IsOnCreditHold],---------------------bit
			[AccountOpenedDate],------------------date
			[StandardDiscountPercentage],---------decimal
			[PaymentDays],------------------------int
			[PhoneNumber],------------------------nvarchar-20
			[FaxNumber],--------------------------nvarchar-20
			[WebsiteURL],-------------------------nvarchar-256
			[DeliveryAddressLine1],---------------nvarchar-60
			[DeliveryPostalCode],-----------------nvarchar-10
			[PostalAddressLine1],-----------------nvarchar-60
			[PostalPostalCode]--------------------nvarchar-10
		)
		VALUES
		(
			ABS(CHECKSUM(NEWID()) % 10),
			ABS(CHECKSUM(NEWID()) % 10),
			ABS(CHECKSUM(NEWID()) % 10),
			ABS(CHECKSUM(NEWID()) % 10),
			ABS(CHECKSUM(NEWID()) % 10),
			ABS(CHECKSUM(NEWID()) % 10),
			ABS(CHECKSUM(NEWID()) % 10),
			LEFT(CONVERT(varchar(255), NEWID()),100),
			1,
			1,
			CAST(CURRENT_TIMESTAMP AS DATE),
			cast(RAND()*1000 as decimal(18,2)),
			ABS(CHECKSUM(NEWID()) % 10),
			LEFT(CONVERT(varchar(255), NEWID()),20),
			LEFT(CONVERT(varchar(255), NEWID()),20),
			LEFT(CONVERT(varchar(255), NEWID()),256),
			LEFT(CONVERT(varchar(255), NEWID()),60),
			LEFT(CONVERT(varchar(255), NEWID()),10),
			LEFT(CONVERT(varchar(255), NEWID()),60),
			CAST(CURRENT_TIMESTAMP AS nvarchar(10)) -- поле с технической разметкой
		)
		set @iter=@iter+1
	END TRY 

	BEGIN CATCH  
		-- вроде и так проскочило :)
		-- в принципе, можно было и вручную запустить несколько раз до 5 успехных срабатываний
	END CATCH 

END


/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

  delete [WideWorldImporters].[Sales].[Customers]
  where [CustomerID] = (select max([CustomerID]) from [WideWorldImporters].[Sales].[Customers])


/*
3. Изменить одну запись, из добавленных через UPDATE
*/

  update [WideWorldImporters].[Sales].[Customers]
  set [CustomerName]='OTUS 202402'
  where [CustomerID] = (select max([CustomerID]) from [WideWorldImporters].[Sales].[Customers])

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/



/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

