CREATE MESSAGE TYPE ReceivedOrders
AUTHORIZATION dbo
VALIDATION = None


CREATE CONTRACT postmessages
(ReceivedOrders SENT BY ANY)


CREATE QUEUE InvQueue
WITH STATUS = ON, RETENTION = OFF



CREATE SERVICE InvService
AUTHORIZATION dbo 
ON QUEUE InvQueue
(postmessages)
go

CREATE OR ALTER PROCEDURE Sales.Inv 
  @CustomerID INT
AS
BEGIN
  DECLARE @XMLMessage XML
 
  CREATE TABLE #Message (
    CustomerID INT PRIMARY KEY
    ,COUNT_INV INT
    )
 
  INSERT INTO #Message ( CustomerID,COUNT_INV)
  SELECT [CustomerID], count(*) as CC
  FROM [WideWorldImporters].[Sales].[Invoices]
  where [CustomerID]=@CustomerID
  group by [CustomerID]
 
     --Creating the XML Message
  SELECT @XMLMessage = (
      SELECT *
      FROM #Message
      FOR XML PATH('Order')
        ,TYPE
      );
 
  DECLARE @Handle UNIQUEIDENTIFIER;
  --Sending the Message to the Queue
  BEGIN
    DIALOG CONVERSATION @Handle
    FROM SERVICE InvService TO SERVICE 'InvService' ON CONTRACT [postmessages]
    WITH ENCRYPTION = OFF;
 
    SEND ON CONVERSATION @Handle MESSAGE TYPE ReceivedOrders(@XMLMessage);
  END 
  GO

DECLARE @i int = 1

while @i<5
	begin
		exec Sales.Inv @i
	set @i=@i+1
	end


SELECT service_name
,priority,
queuing_order,
service_contract_name,
message_type_name,
validation,
message_body,
message_enqueue_time,
status
FROM InvQueue


DECLARE @Handle UNIQUEIDENTIFIER ;
 DECLARE @MessageType SYSNAME ;
 DECLARE @Message XML
 DECLARE @OrderDate DATE
 DECLARE @OrderID INT 
 DECLARE @ProductCode VARCHAR(50)
 DECLARE @Quantity NUMERIC (9,2)
 DECLARE @UnitPrice NUMERIC (9,2)
 
WAITFOR( RECEIVE TOP (1)  
@Handle = conversation_handle,
@MessageType = message_type_name,
@Message = message_body FROM dbo.OrderQueue),TIMEOUT 1000
 
SET @OrderID   =   CAST(CAST(@Message.query('/Order/OrderID/text()') AS NVARCHAR(MAX)) AS INT)
SET @OrderDate   =   CAST(CAST(@Message.query('/Order/OrderDate/text()') AS NVARCHAR(MAX)) AS DATE)
SET @ProductCode =   CAST(CAST(@Message.query('/Order/ProductCode/text()') AS NVARCHAR(MAX)) AS VARCHAR(50))
SET @Quantity    =   CAST(CAST(@Message.query('/Order/Quantity/text()') AS NVARCHAR(MAX)) AS NUMERIC(9,2))
SET @UnitPrice   =   CAST(CAST(@Message.query('/Order/UnitPrice/text()') AS NVARCHAR(MAX)) AS NUMERIC(9,2))
 
PRINT @OrderID
PRINT @OrderDate
PRINT @ProductCode
PRINT @Quantity
PRINT @UnitPrice