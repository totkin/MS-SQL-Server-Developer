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
[���������] [nvarchar](255) NULL,
[������] [nvarchar](255) NULL,
[���������] [nvarchar](255) NULL,
[��������] [nvarchar](255) NULL,
[������������] [nvarchar](255) NULL,
[�����] [nvarchar](255) NULL,
[��������] [nvarchar](255) NULL,
[��������] [nvarchar](255) NULL,
[���] [nvarchar](255) NULL,
[���-��] int NULL,
[������������] [nvarchar](255) NULL,
[��������] [nvarchar](255) NULL,
[���] [nvarchar](255) NULL,
[�������������] [nvarchar](255) NULL,
[�������� ��] [nvarchar](255) NULL,
[����� ��] [nvarchar](255) NULL,
[����] decimal(5,2) NULL,
[�����] decimal(5,2) NULL,
[������ ����] decimal(5,2) NULL,
[����������] [nvarchar](255) NULL,
[������������� ���] [nvarchar](255) NULL,
[����] date NULL,
[����] [nvarchar](MAX) NULL, --����������� �� ����
[��������] int NULL,
[���������] int NULL,
[��� (������)] decimal(5,3) NULL,
[�� % �� �����] decimal(5,3) NULL,
[Source#Name] [nvarchar](255) NULL
) ON [PRIMARY]
GO


CREATE SCHEMA [CLEAR];
GO

CREATE TABLE [CLEAR].[PriceData](
[ID] bigint NOT NULL, -- ID ������, ������������ ������������� �����������
[Food] [nvarchar](255) NULL,
[���������] [nvarchar](255) NULL,
[������] [nvarchar](255) NULL,
[���������] [nvarchar](255) NULL,
[��������] [nvarchar](255) NULL,
[������������] [nvarchar](255) NULL,
[�����] [nvarchar](255) NULL,
[��������] [nvarchar](255) NULL,
[��������] [nvarchar](255) NULL,
[���] [nvarchar](255) NULL,
[���-��] int NULL,
[����� �������] [nvarchar](255) NULL,
[��������] [nvarchar](255) NULL,
[���] [nvarchar](255) NULL,
[�������������] [nvarchar](255) NULL,
[�������� ��] [nvarchar](255) NULL,
[����� ��] [nvarchar](255) NULL,
[����] decimal(5,2) NULL,
[�����] decimal(5,2) NULL,
[������ ����] decimal(5,2) NULL,
[����������] [nvarchar](255) NULL,
[������������� ���] [nvarchar](255) NULL,
[����] date NULL,
[����] [nvarchar](MAX) NULL,
[��������] int NULL,
[���������] int NULL,
[��� (������)] decimal(5,3) NULL,
[�� % �� �����] decimal(5,3) NULL,
[SourceName] [nvarchar](255) NULL,
[TTID] bigint NULL,
[SKUID] bigint NULL,
CONSTRAINT PK_CLEAR_PriceData PRIMARY KEY CLUSTERED ([ID])
) ON [PRIMARY]
GO


CREATE TABLE [CLEAR].[SKU](
[SKUID] bigint NOT NULL identity(1, 1),
[Food] [nvarchar](255) NULL,
[���������] [nvarchar](255) NULL,
[������] [nvarchar](255) NULL,
[���������] [nvarchar](255) NULL,
[��������] [nvarchar](255) NULL,
[������������] [nvarchar](255) NULL,
[�����] [nvarchar](255) NULL,
[��������] [nvarchar](255) NULL,
[��������] [nvarchar](255) NULL,
[���] [nvarchar](255) NULL,
[������������] [nvarchar](255) NULL,
[��������] [nvarchar](255) NULL,
[���] [nvarchar](255) NULL,
[�������������] [nvarchar](255) NULL,
[������������� ���] [nvarchar](255) NULL,
CONSTRAINT PK_CLEAR_SKU PRIMARY KEY CLUSTERED ([SKUID])
) ON [PRIMARY]
GO


CREATE TABLE [CLEAR].[TT](
[TTID] bigint NOT NULL identity(1, 1),
[�������� ��] [nvarchar](255) NULL,
[����� ��] [nvarchar](255) NULL,
[����] [nvarchar](255) NULL,
[������ �����] [nvarchar](255) NULL,
CONSTRAINT PK_CLEAR_TT PRIMARY KEY CLUSTERED ([TTID])
) ON [PRIMARY]
GO


CREATE TABLE [CLEAR].[DATA](
[ID] bigint NOT NULL,
[SKUID] bigint NOT NULL,
[TTID] bigint NOT NULL,
[DATE] date NOT NULL, -- ex����
[���-��] int NULL,
[����] decimal(5,2) NULL,
[�����] decimal(5,2) NULL,
[������ ����] decimal(5,2) NULL,
[�� % �� �����] decimal(5,3) NULL,
CONSTRAINT PK_CLEAR_DATA PRIMARY KEY CLUSTERED ([ID]),
CONSTRAINT UC_CLEAR_DATA UNIQUE ([SKUID], [TTID], [DATE])
) ON [PRIMARY]
GO

ALTER TABLE [CLEAR].[DATA] ADD CONSTRAINT [CLEAR_DATA_SKUID_FOREIGN] FOREIGN KEY([SKUID]) REFERENCES [CLEAR].[SKU]([SKUID]);
ALTER TABLE [CLEAR].[DATA] ADD CONSTRAINT [CLEAR_DATA_TTID_FOREIGN] FOREIGN KEY([TTID]) REFERENCES [CLEAR].[TT]([TTID]);


CREATE TABLE [CLEAR].[DETAILS](
[ID] bigint NOT NULL,
[����������] [nvarchar](255) NULL,
[����] [nvarchar](MAX) NULL,
CONSTRAINT PK_CLEAR_DETAILS PRIMARY KEY CLUSTERED ([ID])
) ON [PRIMARY]
GO

ALTER TABLE [CLEAR].[DETAILS] ADD CONSTRAINT [CLEAR_DETAILS_SKUID_FOREIGN] FOREIGN KEY([ID]) REFERENCES [CLEAR].[DATA]([ID]);
