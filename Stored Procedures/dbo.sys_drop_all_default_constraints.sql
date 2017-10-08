SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[sys_drop_all_default_constraints] (@table_name sysname)
AS

DECLARE @df_name sysname
DECLARE @sql nvarchar(1000)

DECLARE cc CURSOR
FOR
SELECT NAME 
FROM sys.default_constraints
WHERE parent_object_id = OBJECT_ID(@table_name) 

OPEN cc
FETCH NEXT FROM cc INTO @df_name

WHILE @@FETCH_STATUS = 0
BEGIN
	IF @df_name IS NOT NULL
	BEGIN
		PRINT @df_name
		SET @sql = 'ALTER TABLE ' + @table_name + ' DROP CONSTRAINT  ' + @df_name
		EXEC sp_executesql @sql
	END

	FETCH NEXT FROM cc INTO @df_name
END

CLOSE cc
DEALLOCATE cc
GO
