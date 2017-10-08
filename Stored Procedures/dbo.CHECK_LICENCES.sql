SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CHECK_LICENCES](@version int) AS

DECLARE @count int

SELECT @count = COUNT(*)
FROM dbo.LICENSES
WHERE MAX_VERSION < @version

IF @count = 0 RETURN (0)

DECLARE @s varchar(1000)

SET @s = 
  '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!' + CHAR(13) +
  'This version of program will not work properly because of license limitations!' + CHAR(13) + 
  CONVERT(varchar(10), @count)  + ' branches/departments have version limitations.' + CHAR(13) + 
  '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!' + CHAR(13)

PRINT @s
RETURN (1)
GO
