SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[SYS_SQL_CONFIG] AS

SET NOCOUNT ON

DECLARE @db_name sysname

SET @db_name = DB_NAME()
exec sp_dboption @db_name, 'recursive triggers', 'false'
exec sp_configure  'nested triggers', 1
RECONFIGURE
GO
