/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/

DECLARE @xmlDocument xml
DECLARE @docHandle int;

-- чтение
SELECT @xmlDocument = BulkColumn
FROM OPENROWSET(BULK '/var/opt/mssql/otusdata/StockItems-188-1fb5df.xml', SINGLE_CLOB) as data

-- предпоготовка: создание представления документа
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument;



-- изучение структуры документа
with C as
(
  select T.X.value('local-name(.)', 'nvarchar(max)') as Structure,
         T.X.query('*') as SubNodes,
         T.X.exist('*') as HasSubNodes
  from @xmlDocument.nodes('*') as T(X)
  union all
  select C.structure + N'/' + T.X.value('local-name(.)', 'nvarchar(max)'),
         T.X.query('*'),
         T.X.exist('*')
  from C
    cross apply C.SubNodes.nodes('*') as T(X)
)
select DISTINCT C.Structure
from C
where C.HasSubNodes = 0;


-- выборка во временную таблицу

-- вариант XQuery. РАБОТАЕТ, но закомменчен
/*
IF OBJECT_ID('tempdb..#temp_Warehouse_StockItems') IS NOT NULL
    drop table #temp_Warehouse_StockItems

SELECT
	x.value('@Name', 'nvarchar(255)') AS [StockItemName],
	x.value('(IsChillerStock)[1]', 'bit') AS [IsChillerStock],
	x.value('(SupplierID)[1]', 'int') AS [SupplierID],
	x.value('(TaxRate)[1]', 'decimal(18, 3)') AS [TaxRate],
	x.value('(UnitPrice)[1]', 'decimal(18, 2)') AS [UnitPrice],
	x.value('(Package/OuterPackageID)[1]', 'int') AS [OuterPackageID],
	x.value('(Package/QuantityPerOuter)[1]', 'int') AS [QuantityPerOuter],
	x.value('(Package/TypicalWeightPerUnit)[1]', 'decimal(18, 3)') AS [TypicalWeightPerUnit],
	x.value('(Package/UnitPackageID)[1]', 'int') AS [UnitPackageID]
INTO #temp_Warehouse_StockItems
FROM
@xmlDocument.nodes('StockItems/Item') TempXML1 (x)

*/

-- вариант OPENXML

IF OBJECT_ID('tempdb..#temp_Warehouse_StockItems') IS NOT NULL
    drop table #temp_Warehouse_StockItems

SELECT *
INTO #temp_Warehouse_StockItems
FROM OPENXML (@docHandle,'/StockItems/Item')
WITH (
	[StockItemName]        [nvarchar](100)   '@Name',
	[IsChillerStock]       [bit]             'IsChillerStock',
	[OuterPackageID]       [int]             'Package/OuterPackageID',
	[QuantityPerOuter]     [int]             'Package/QuantityPerOuter',
	[TypicalWeightPerUnit] [decimal](18, 3)  'Package/TypicalWeightPerUnit',
	[UnitPackageID]        [int]             'Package/UnitPackageID',
	[SupplierID]           [int]             'SupplierID',
	[TaxRate]              [decimal](18, 3)  'TaxRate',
	[UnitPrice]            [decimal](18, 2)  'UnitPrice');


-- MERGE
DECLARE @SummaryOfChanges TABLE (Change VARCHAR(20));

MERGE Warehouse.StockItems AS T_Base
USING #temp_Warehouse_StockItems AS T_Source
ON (T_Base.[StockItemName] = T_Source.[StockItemName])
WHEN MATCHED THEN
    UPDATE SET 
	[IsChillerStock] = T_Source.[IsChillerStock],
	[OuterPackageID] = T_Source.[OuterPackageID],
	[QuantityPerOuter] = T_Source.[QuantityPerOuter],
	[TypicalWeightPerUnit] = T_Source.[TypicalWeightPerUnit],
	[UnitPackageID] = T_Source.[UnitPackageID],
	[SupplierID] = T_Source.[SupplierID],
	[TaxRate] = T_Source.[TaxRate],
	[UnitPrice] = T_Source.[UnitPrice],
	[Brand] = N'Otus' -- just for fun :)
WHEN NOT MATCHED THEN
	-- добавлено 2 поля, которых нет в файле, но которые нужны при добалвении (поставлены заглушки
    INSERT ([StockItemName],[IsChillerStock],[OuterPackageID],[QuantityPerOuter],[TypicalWeightPerUnit],[UnitPackageID],[SupplierID],[TaxRate],[UnitPrice],
			[LastEditedBy],[LeadTimeDays],[Brand])
	VALUES (T_Source.[StockItemName],T_Source.[IsChillerStock],T_Source.[OuterPackageID],T_Source.[QuantityPerOuter],T_Source.[TypicalWeightPerUnit],
			T_Source.[UnitPackageID],T_Source.[SupplierID],T_Source.[TaxRate],T_Source.[UnitPrice],
			ABS(CHECKSUM(NEWID()) % 10)+1,ABS(CHECKSUM(NEWID()) % 10)+1,N'Otus')
OUTPUT $action
INTO @SummaryOfChanges;

SELECT Change,
    COUNT(*) AS CountPerChange
FROM @SummaryOfChanges
GROUP BY Change;

select *
from Warehouse.StockItems
where [StockItemName] in (select [StockItemName] from #temp_Warehouse_StockItems)



-- удалить представление документа
EXEC sp_xml_removedocument @docHandle;



/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

--EXEC master.dbo.sp_configure 'show advanced options', 1
--RECONFIGURE
--EXEC master.dbo.sp_configure 'xp_cmdshell', 1
--RECONFIGURE

DECLARE @strCommand nvarchar(max)='bcp "{SQL}" queryout "{FILE}" -T -c -t,'
DECLARE @strSQL     nvarchar(max)
DECLARE @strFILE    nvarchar(max)='/var/opt/mssql/otusdata/StockItems.xml'


set @strSQL=REPLACE('
SELECT
	[StockItemName]        as ''@Name'',
	[IsChillerStock]       as ''IsChillerStock'',
	[OuterPackageID]       as ''Package/OuterPackageID'',
	[QuantityPerOuter]     as ''Package/QuantityPerOuter'',
	[TypicalWeightPerUnit] as ''Package/TypicalWeightPerUnit'',
	[UnitPackageID]        as ''Package/UnitPackageID'',
	[SupplierID]           as ''SupplierID'',
	[TaxRate]              as ''TaxRate'',
	[UnitPrice]            as ''UnitPrice''
FROM [WideWorldImporters].[Warehouse].[StockItems] FOR XML PATH(''Item''), ROOT(''StockItems'')
',char(13) + char(10),' ')

WHILE CHARINDEX('  ',@strSQL) <> 0
 SET @strSQL = REPLACE(@strSQL,'  ',' ');

SET @strCommand=replace(replace(@strCommand,'{SQL}',@strSQL),'{FILE}',@strFILE)
EXEC xp_cmdshell @strCommand


/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

select 
StockItemID,StockItemName,
JSON_VALUE(CustomFields,'$.CountryOfManufacture') as CountryOfManufacture,
(select top(1) [Value] from OPENJSON(CustomFields)) as FirstTag
from [Warehouse].[StockItems] as S


/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/


select 
StockItemID,StockItemName,
STUFF( (SELECT ', ' + [key]
		FROM OPENJSON([CustomFields])
		FOR XML PATH ('')),
		1, 2, '') as [все теги (из CustomFields) через запятую в одном поле]
from [Warehouse].[StockItems] as S
CROSS APPLY OPENJSON(S.[CustomFields],'$.Tags') as T
where T.[value]='Vintage'