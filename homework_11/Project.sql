USE [master]
GO

CREATE DATABASE [OTUSDATA]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'OTUS_Primary', FILENAME = N'/var/opt/mssql/data/OTUSDATA.mdf' , SIZE = 1048576KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB ), 
 FILEGROUP [USERDATA]  DEFAULT
( NAME = N'OTUS_UserData', FILENAME = N'/var/opt/mssql/data/OTUSDATA_UserData.ndf' , SIZE = 2097152KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB ), 
 FILEGROUP [OTUS_InMemory_Data] CONTAINS MEMORY_OPTIMIZED_DATA  DEFAULT
( NAME = N'OTUS_InMemory_Data_1', FILENAME = N'/var/opt/mssql/data/OTUSDATA_InMemory_Data_1' , MAXSIZE = UNLIMITED)
 LOG ON 
( NAME = N'OTUS_Log', FILENAME = N'/var/opt/mssql/data/OTUSDATA.ldf' , SIZE = 102400KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT
GO

IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [OTUSDATA].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO

USE [OTUSDATA];

CREATE SCHEMA [INPUT];
GO


CREATE TABLE [INPUT].[PriceData_BUFFER](
[ID] [nvarchar](255) NULL,
[Food] [nvarchar](255) NULL,
[Категория] [nvarchar](255) NULL,
[Группа] [nvarchar](255) NULL,
[Подгруппа] [nvarchar](255) NULL,
[Штрихкод] [nvarchar](255) NULL,
[Наименование] [nvarchar](255) NULL,
[Бренд] [nvarchar](255) NULL,
[Саббренд] [nvarchar](255) NULL,
[Оболочка] [nvarchar](255) NULL,
[Вес] [nvarchar](255) NULL,
[Кол-во] int NULL,
[Формавыпуска] [nvarchar](255) NULL,
[Упаковка] [nvarchar](255) NULL,
[ЧТМ] [nvarchar](255) NULL,
[Производитель] [nvarchar](255) NULL,
[Название ТТ] [nvarchar](255) NULL,
[Адрес ТТ] [nvarchar](255) NULL,
[Цена] decimal(5,2) NULL,
[Акция] decimal(5,2) NULL,
[Старая цена] decimal(5,2) NULL,
[Примечание] [nvarchar](255) NULL,
[Производитель ЧТМ] [nvarchar](255) NULL,
[Дата] date NULL,
[Фото] [nvarchar](MAX) NULL, --гиперссылка на фото
[ГодМесяц] int NULL,
[ГодНеделя] int NULL,
[Вес (числом)] decimal(5,3) NULL,
[Ср % по акции] decimal(5,3) NULL,
[Source#Name] [nvarchar](255) NULL
) ON [PRIMARY]
GO


CREATE SCHEMA [CLEAR];
GO

CREATE TABLE [CLEAR].[PriceData](
[ID] bigint NOT NULL, -- ID строки, уникальность гарантирована поставщиком
[Food] [nvarchar](255) NULL,
[Категория] [nvarchar](255) NULL,
[Группа] [nvarchar](255) NULL,
[Подгруппа] [nvarchar](255) NULL,
[Штрихкод] [nvarchar](255) NULL,
[Наименование] [nvarchar](255) NULL,
[Бренд] [nvarchar](255) NULL,
[Саббренд] [nvarchar](255) NULL,
[Оболочка] [nvarchar](255) NULL,
[Вес] [nvarchar](255) NULL,
[Кол-во] int NULL,
[Форма выпуска] [nvarchar](255) NULL,
[Упаковка] [nvarchar](255) NULL,
[ЧТМ] [nvarchar](255) NULL,
[Производитель] [nvarchar](255) NULL,
[Название ТТ] [nvarchar](255) NULL,
[Адрес ТТ] [nvarchar](255) NULL,
[Цена] decimal(5,2) NULL,
[Акция] decimal(5,2) NULL,
[Старая цена] decimal(5,2) NULL,
[Примечание] [nvarchar](255) NULL,
[Производитель ЧТМ] [nvarchar](255) NULL,
[Дата] date NULL,
[Фото] [nvarchar](MAX) NULL,
[ГодМесяц] int NULL,
[ГодНеделя] int NULL,
[Вес (числом)] decimal(5,3) NULL,
[Ср % по акции] decimal(5,3) NULL,
[SourceName] [nvarchar](255) NULL,
[TTID] bigint NULL,
[SKUID] bigint NULL,
CONSTRAINT PK_CLEAR_PriceData PRIMARY KEY CLUSTERED ([ID])
) ON [PRIMARY]
GO


CREATE TABLE [CLEAR].[SKU](
[SKUID] bigint NOT NULL identity(1, 1),
[Food] [nvarchar](255) NULL,
[Категория] [nvarchar](255) NULL,
[Группа] [nvarchar](255) NULL,
[Подгруппа] [nvarchar](255) NULL,
[Штрихкод] [nvarchar](255) NULL,
[Наименование] [nvarchar](255) NULL,
[Бренд] [nvarchar](255) NULL,
[Саббренд] [nvarchar](255) NULL,
[Оболочка] [nvarchar](255) NULL,
[Вес] [nvarchar](255) NULL,
[Формавыпуска] [nvarchar](255) NULL,
[Упаковка] [nvarchar](255) NULL,
[ЧТМ] [nvarchar](255) NULL,
[Производитель] [nvarchar](255) NULL,
[Производитель ЧТМ] [nvarchar](255) NULL,
CONSTRAINT PK_CLEAR_SKU PRIMARY KEY CLUSTERED ([SKUID])
) ON [PRIMARY]
GO


CREATE TABLE [CLEAR].[TT](
[TTID] bigint NOT NULL identity(1, 1),
[Название ТТ] [nvarchar](255) NULL,
[Адрес ТТ] [nvarchar](255) NULL,
[Сеть] [nvarchar](255) NULL,
[Группа сетей] [nvarchar](255) NULL,
CONSTRAINT PK_CLEAR_TT PRIMARY KEY CLUSTERED ([TTID])
) ON [PRIMARY]
GO


CREATE TABLE [CLEAR].[DATA](
[ID] bigint NOT NULL,
[SKUID] bigint NOT NULL,
[TTID] bigint NOT NULL,
[DATE] date NOT NULL, -- exДата
[Кол-во] int NULL,
[Цена] decimal(5,2) NULL,
[Акция] decimal(5,2) NULL,
[Старая цена] decimal(5,2) NULL,
[Ср % по акции] decimal(5,3) NULL,
CONSTRAINT PK_CLEAR_DATA PRIMARY KEY CLUSTERED ([ID]),
CONSTRAINT UC_CLEAR_DATA UNIQUE ([SKUID], [TTID], [DATE])
) ON [PRIMARY]
GO

ALTER TABLE [CLEAR].[DATA] ADD CONSTRAINT [CLEAR_DATA_SKUID_FOREIGN] FOREIGN KEY([SKUID]) REFERENCES [CLEAR].[SKU]([SKUID]);
ALTER TABLE [CLEAR].[DATA] ADD CONSTRAINT [CLEAR_DATA_TTID_FOREIGN] FOREIGN KEY([TTID]) REFERENCES [CLEAR].[TT]([TTID]);


CREATE TABLE [CLEAR].[DETAILS](
[ID] bigint NOT NULL,
[Примечание] [nvarchar](255) NULL,
[Фото] [nvarchar](MAX) NULL,
CONSTRAINT PK_CLEAR_DETAILS PRIMARY KEY CLUSTERED ([ID])
) ON [PRIMARY]
GO

ALTER TABLE [CLEAR].[DETAILS] ADD CONSTRAINT [CLEAR_DETAILS_SKUID_FOREIGN] FOREIGN KEY([ID]) REFERENCES [CLEAR].[DATA]([ID]);
