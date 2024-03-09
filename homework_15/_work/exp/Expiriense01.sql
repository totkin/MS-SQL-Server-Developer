--Включение компонента Service Broker и переход на базу данных WideWorldImporters
USE master;

select is_broker_enabled
from sys.databases
where name='WideWorldImporters'

USE master
ALTER DATABASE WideWorldImporters SET ENABLE_BROKER  WITH ROLLBACK IMMEDIATE



ALTER DATABASE [WideWorldImporters] SET ENABLE_BROKER;
GO

USE [WideWorldImporters];
GO

--Создание типов сообщений
CREATE MESSAGE TYPE
           [//WWI/OTUS/RequestMessage]
           VALIDATION = WELL_FORMED_XML;
CREATE MESSAGE TYPE
		[//WWI/OTUS/ReplyMessage]
		VALIDATION = WELL_FORMED_XML;
GO

--Создание контракта
CREATE CONTRACT [//WWI/OTUS/HW15Contract]
        ([//WWI/OTUS/RequestMessage]
        SENT BY INITIATOR,
        [//WWI/OTUS/ReplyMessage]
        SENT BY TARGET
        );
GO

--Создание целевой очереди и службы
CREATE QUEUE TargetOTUSDB;

CREATE SERVICE
        [//WWI/OTUS/TargetService]
        ON QUEUE TargetOTUSDB
        ([//WWI/OTUS/HW15Contract]);
GO

--Создание очереди инициатора и службы
CREATE QUEUE InitiatorOTUSDB;

CREATE SERVICE
        [//WWI/OTUS/InitiatorService]
        ON QUEUE InitiatorOTUSDB;
GO



--Начало обмена сообщениями
DECLARE @InitDlgHandle UNIQUEIDENTIFIER;
DECLARE @RequestMsg NVARCHAR(100);

BEGIN TRANSACTION;

BEGIN DIALOG @InitDlgHandle
        FROM SERVICE
        [//WWI/OTUS/InitiatorService]
        TO SERVICE
        N'//WWI/OTUS/TargetService'
        ON CONTRACT
        [//WWI/OTUS/HW15Contract]
        WITH
            ENCRYPTION = OFF;

SELECT @RequestMsg = N'<RequestMsg>Message for Target service from OTUS.</RequestMsg>';

SEND ON CONVERSATION @InitDlgHandle
        MESSAGE TYPE [//WWI/OTUS/RequestMessage] (@RequestMsg);

SELECT @RequestMsg AS SentRequestMsg;

COMMIT TRANSACTION;
GO


--Получение запроса и отправка ответа
DECLARE @RecvReqDlgHandle UNIQUEIDENTIFIER;
DECLARE @RecvReqMsg NVARCHAR(100);
DECLARE @RecvReqMsgName sysname;

BEGIN TRANSACTION;

WAITFOR
( RECEIVE TOP(1)
    @RecvReqDlgHandle = conversation_handle,
    @RecvReqMsg = message_body,
    @RecvReqMsgName = message_type_name
    FROM TargetOTUSDB
), TIMEOUT 1000;

SELECT @RecvReqMsg AS ReceivedRequestMsg;

IF @RecvReqMsgName =
    N'//WWI/OTUS/RequestMessage'
BEGIN
        DECLARE @ReplyMsg NVARCHAR(100);
        SELECT @ReplyMsg =
        N'<ReplyMsg>Message for Initiator service from OTUS.</ReplyMsg>';

        SEND ON CONVERSATION @RecvReqDlgHandle
            MESSAGE TYPE
            [//WWI/OTUS/ReplyMessage]
            (@ReplyMsg);

        END CONVERSATION @RecvReqDlgHandle;
END

SELECT @ReplyMsg AS SentReplyMsg;

COMMIT TRANSACTION;
GO


--Получение ответа и завершение обмена
DECLARE @RecvReplyMsg NVARCHAR(100);
DECLARE @RecvReplyDlgHandle UNIQUEIDENTIFIER;

BEGIN TRANSACTION;

WAITFOR
( RECEIVE TOP(1)
    @RecvReplyDlgHandle = conversation_handle,
    @RecvReplyMsg = message_body
    FROM InitiatorOTUSDB
), TIMEOUT 1000;

END CONVERSATION @RecvReplyDlgHandle;

SELECT @RecvReplyMsg AS ReceivedReplyMsg;

COMMIT TRANSACTION;
GO



-- 
CREATE OR ALTER PROC Sales.SendInvoice
	@CustomerID INT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @InitDlgHandle UNIQUEIDENTIFIER;
	DECLARE @RequestMsg NVARCHAR(MAX);
	
	BEGIN TRAN

		SELECT @RequestMsg = (SELECT COUNT(*) AS [COUNT]
								  FROM Sales.Invoices
								  WHERE [CustomerID] = @CustomerID
								  FOR XML AUTO, root('RequestMessage')); 
	
		BEGIN DIALOG @InitDlgHandle
        FROM SERVICE [//WWI/OTUS/InitiatorService]
        TO SERVICE N'//WWI/OTUS/TargetService'
        ON CONTRACT [//WWI/OTUS/HW15Contract]
        WITH ENCRYPTION = OFF;


		SEND ON CONVERSATION @InitDlgHandle
        MESSAGE TYPE [//WWI/OTUS/RequestMessage] (@RequestMsg);
	
	COMMIT TRAN 
END
GO









--Завершение работы, учничтожение объектов
IF EXISTS (SELECT * FROM sys.services WHERE name = N'//WWI/OTUS/TargetService')
	DROP SERVICE [//WWI/OTUS/TargetService];

IF EXISTS (SELECT * FROM sys.service_queues WHERE name = N'TargetOTUSDB')
	DROP QUEUE TargetOTUSDB;

IF EXISTS (SELECT * FROM sys.services WHERE name = N'//WWI/OTUS/InitiatorService')
	DROP SERVICE [//WWI/OTUS/InitiatorService];

IF EXISTS (SELECT * FROM sys.service_queues WHERE name = N'InitiatorOTUSDB')
	DROP QUEUE InitiatorOTUSDB;

IF EXISTS (SELECT * FROM sys.service_contracts WHERE name = N'//WWI/OTUS/HW15Contract')
	DROP CONTRACT [//WWI/OTUS/HW15Contract];

IF EXISTS (SELECT * FROM sys.service_message_types WHERE name = N'//WWI/OTUS/RequestMessage')
	DROP MESSAGE TYPE [//WWI/OTUS/RequestMessage];

IF EXISTS (SELECT * FROM sys.service_message_types WHERE name = N'//WWI/OTUS/ReplyMessage')
	DROP MESSAGE TYPE [//WWI/OTUS/ReplyMessage];
GO