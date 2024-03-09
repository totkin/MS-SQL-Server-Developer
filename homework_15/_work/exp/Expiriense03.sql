-- �������� SERVICE ��� ���� ��������
CREATE SERVICE ReportService ON QUEUE ReportQueue;
CREATE SERVICE ProcessedReportService ON QUEUE ProcessedReportQueue;

-- �������� MESSAGE TYPE
CREATE MESSAGE TYPE [//OTUS/ReportGeneration] VALIDATION = WELL_FORMED_XML;
IF EXISTS (SELECT * FROM sys.service_message_types WHERE name = N'//OTUS/ProcessedReport')
	DROP MESSAGE TYPE [//OTUS/ProcessedReport];
CREATE MESSAGE TYPE [//OTUS/ProcessedReport] AUTHORIZATION [dbo];

-- �������� CONTRACT ��� ����� ��������
IF EXISTS (SELECT * FROM sys.service_contracts WHERE name = N'ReportContract')
	DROP CONTRACT [ReportContract];
CREATE CONTRACT ReportContract(    
    ReportGeneration SENT BY INITIATOR,    
    [//OTUS/ProcessedReport] SENT BY TARGET);

-- �������� ������� ��� ������������ �������
CREATE QUEUE ReportQueue;
go

-- �������� ��������� ��� ���������� � ������� ������ �� ������������ ������
CREATE OR ALTER PROCEDURE Sales.AddReportRequest
AS
BEGIN    
    DECLARE @customerId INT = 1;    
    DECLARE @startDate DATE = '2023-01-01';    
    DECLARE @endDate DATE = '2023-12-31';    
    DECLARE @reportBody NVARCHAR(MAX);    
    DECLARE @conversation_handle UNIQUEIDENTIFIER;
    
    SET @reportBody = 'This is the generated report for customer ' + CONVERT(NVARCHAR(10), @customerId) + ' from ' + CONVERT(NVARCHAR(20), @startDate) + ' to ' + CONVERT(NVARCHAR(20), @endDate);
    
    BEGIN DIALOG CONVERSATION @conversation_handle    
    FROM SERVICE ReportService TO SERVICE 'ProcessedReportService' ON CONTRACT ReportContract    
    WITH ENCRYPTION=OFF, LIFETIME = 60;

    -- �������� ������� � �������    
    SEND ON CONVERSATION @conversation_handle MESSAGE TYPE [ReportGeneration] (@reportBody);
END;

-- �������� ������� ��� ��������� ������� � �������� �����������
CREATE QUEUE ProcessedReportQueue;
go

-- �������� ��������� ��� ��������� �������
CREATE OR ALTER PROCEDURE ProcessReportQueue
AS
BEGIN    
    DECLARE @customerId INT;    
    DECLARE @startDate DATE;    
    DECLARE @endDate DATE;    
    DECLARE @conversation_handle UNIQUEIDENTIFIER;
    
    WHILE (1 = 1)    
    BEGIN        
        -- ��������� ������ �� ������������ ������ �� �������        
        RECEIVE TOP(1) @customerId = CustomerID, @startDate = StartDate, @endDate = EndDate, @conversation_handle = CONVERSATION_HANDLE        
        FROM ReportQueue;

        -- ������������ ������ �� ���������� ������� (Orders) �� ������� �� �������� ������ �������                
        INSERT INTO [Reports].[CustomerOrders]        
        SELECT CustomerID, COUNT(OrderID) AS TotalOrders        
        FROM [Sales].[Orders]        
        WHERE CustomerID = @customerId        
        AND OrderDate BETWEEN @startDate AND @endDate        
        GROUP BY CustomerID;

        -- ����������� ������������ ������ � ������ �������                
        SEND ON CONVERSATION @conversation_handle MESSAGE TYPE [//OTUS/Report] (@customerId, @startDate, @endDate)        
        FROM ReportQueue TO ProcessedReportQueue;    
    END;
END;