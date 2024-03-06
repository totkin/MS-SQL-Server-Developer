-- Первично, индексы были созданы в предыдущем задании.
-- Опытная эксплуатация покажет необходимые направления развития.
-- В рамках домашнего задания создана дополнительная таблица и на нее поставлены индексы.
-- Работы произведены в рамках тестирования возможностей MS SQL Server


USE [OTUSDATA]
GO

DROP TABLE IF EXISTS [INPUT].[Index_Test]

CREATE TABLE [INPUT].[Index_Test](
	[ID] [bigint] NOT NULL PRIMARY KEY,
	[Food] [nvarchar](255) NULL,
	[Штрихкод] [nvarchar](255) NULL,
	[Цена] [decimal](5, 2) NULL,
	[Акция] [decimal](5, 2) NULL,
	[Discount] DECIMAL(10, 2),
	[Description_Short] NVARCHAR(100) NOT NULL,
	[Description] NVARCHAR(MAX) NOT NULL
) ON [USERDATA]
GO


--Некластеризованный индекс:
CREATE NONCLUSTERED INDEX IX_Food ON [INPUT].[Index_Test] ([Food]);

--Уникальный индекс:
CREATE UNIQUE INDEX UI_UniqueShtrikhcode ON [INPUT].[Index_Test] ([Штрихкод]);

--Фильтрованный индекс:
CREATE NONCLUSTERED INDEX IX_ActivePrices ON [INPUT].[Index_Test] ([Цена]) WHERE [Акция] > 0;



--Варианты создания индексов
ALTER TABLE [INPUT].[Index_Test]
ADD [IsAvailable] BIT
GO
CREATE INDEX IX_IsAvailable ON [INPUT].[Index_Test] (IsAvailable);




ALTER TABLE [INPUT].[Index_Test] ADD
	[Rate] INT,
	[Date] DATE,
	[Some_XML_Data] [xml] NULL,
	GeoLocationColumn GEOGRAPHY
GO


-- Удаление существующего индекса, если он существует
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_CompositeIndexName')
    DROP INDEX IX_CompositeIndexName ON [INPUT].[Index_Test];

--Индекс по нескольким полям:
CREATE NONCLUSTERED INDEX IX_CompositeIndexName ON [INPUT].[Index_Test] ([Rate], [Date]);


-- Полнотекстовый
CREATE UNIQUE INDEX UI_FullSearch_Index_Test_Description ON [INPUT].[Index_Test]([Description_Short]);

IF FULLTEXTSERVICEPROPERTY('IsFullTextInstalled')=1
BEGIN
	-- Если установлен компонент
	CREATE FULLTEXT CATALOG FTCatalogue AS DEFAULT;
	CREATE FULLTEXT INDEX ON [INPUT].[Index_Test]([Description])
	   KEY INDEX UI_FullSearch_Index_Test_Description
	   WITH STOPLIST = SYSTEM;
END


--XML индекс:
CREATE PRIMARY XML INDEX PXML_TableName_ColumnName ON [INPUT].[Index_Test] ([Some_XML_Data]);



--Итог
SELECT name, index_id, type_desc, is_unique, filter_definition
FROM sys.indexes
WHERE OBJECT_NAME (object_id) = N'Index_Test'
order by index_id