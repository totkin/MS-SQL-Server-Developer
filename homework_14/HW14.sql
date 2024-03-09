use master;  
-- Replace SQL_Server_logon with your SQL Server user credentials.  
GRANT EXTERNAL ACCESS ASSEMBLY TO [SQL_Server_logon];   
-- Modify the following line to specify a different database.  
ALTER DATABASE master SET TRUSTWORTHY ON;  
  
-- Modify the next line to use the appropriate database.  
CREATE ASSEMBLY tvfEventLog   
FROM 'C:\OTUS2024.dll'   
WITH PERMISSION_SET = EXTERNAL_ACCESS;  
GO  
CREATE OR ALTER FUNCTION ReadEventLog(@logname nvarchar(100))
RETURNS TABLE   
(logTime datetime,Message nvarchar(4000),Category nvarchar(4000),InstanceId bigint)  
AS   
EXTERNAL NAME tvfEventLog.OTUSTabularEventLog.InitMethod;
GO

-- Select the top 100 events,
SELECT TOP 100 *
FROM dbo.ReadEventLog(N'Security') as T;
go

-- Select the last 10 login events.
SELECT TOP 10 T.logTime, T.Message, T.InstanceId
FROM dbo.ReadEventLog(N'Security') as T
WHERE T.Category = N'Logon/Logoff';
go


----------------------------------------------------------------------------------------------

CREATE OR ALTER FUNCTION FindInvalidEmails(@ModifiedSince datetime)
RETURNS TABLE (  
   PersonID int,  
   EmailAddress nvarchar(256)  
)  
AS EXTERNAL NAME tvfEventLog.UserDefinedFunctions.[OTUSFindInvalidEmails];
go  
  
SELECT * FROM FindInvalidEmails('2016-05-31');  
go  