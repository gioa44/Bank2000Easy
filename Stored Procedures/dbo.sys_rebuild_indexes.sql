SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[sys_rebuild_indexes] (@min_fragmentation float = null, @mode varchar(20) = 'LIMITED')
AS

SET NOCOUNT ON;

DECLARE 
	@msg varchar(max),
	@sql nvarchar(4000),
	@database_id int,
	@schema sysname, 
	@table_name sysname, 
	@index_name sysname, 
	@avg_freagmentation float

SET @database_id = db_id()

DECLARE cc CURSOR LOCAL FAST_FORWARD FOR
	SELECT SCHEMA_NAME(tbl.schema_id) AS [schema], tbl.name as table_name, i.name as index_name, fi.avg_fragmentation_in_percent AS avg_freagmentation
	FROM sys.tables AS tbl
		INNER JOIN sys.indexes AS i ON (i.index_id > 0 and i.is_hypothetical = 0) AND (i.object_id=tbl.object_id)
		INNER JOIN sys.dm_db_index_physical_stats(@database_id, NULL, NULL, NULL, @mode) AS fi ON fi.object_id=CAST(i.object_id AS int) AND fi.index_id=CAST(i.index_id AS int)
	WHERE (@min_fragmentation IS NULL) OR (fi.avg_fragmentation_in_percent > @min_fragmentation)

OPEN cc

FETCH NEXT FROM cc INTO @schema, @table_name, @index_name, @avg_freagmentation

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @msg = @schema + '.' + @table_name + ' -> ' + @index_name + ' : ' + str(@avg_freagmentation)
	PRINT @msg

	SET @sql = 'ALTER INDEX ' + '[' + @index_name + '] ON ' + @schema + '.[' + @table_name + '] REBUILD'
	--print @sql
	EXEC sp_executesql @sql

	FETCH NEXT FROM cc INTO @schema, @table_name, @index_name, @avg_freagmentation
END

CLOSE cc
DEALLOCATE cc
GO
