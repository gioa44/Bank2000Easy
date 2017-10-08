SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[sys_drop_all_constraints] (@table_name sysname, @drop_pk bit = 0)
AS

DECLARE 
  @pk_name sysname,
  @fk_table_name sysname,
  @constraint_name sysname,
  @s varchar(1000)


SELECT @pk_name = CONSTRAINT_NAME
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE TABLE_NAME = @table_name AND CONSTRAINT_TYPE = 'PRIMARY KEY'

IF @pk_name IS NOT NULL
BEGIN
	DECLARE cc1 CURSOR fast_forward 
	FOR 
	SELECT A.CONSTRAINT_NAME, B.TABLE_SCHEMA + '.' + B.TABLE_NAME
	FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS A
		INNER JOIN INFORMATION_SCHEMA.CONSTRAINT_TABLE_USAGE B ON B.CONSTRAINT_NAME = A.CONSTRAINT_NAME
	WHERE UNIQUE_CONSTRAINT_NAME = @pk_name

	OPEN cc1 
	FETCH NEXT FROM cc1 INTO @constraint_name, @fk_table_name
	WHILE @@fetch_status = 0 
	BEGIN 
		SET @s = 'removing constraint: ' + @constraint_name
		PRINT @s
		
		EXEC('ALTER TABLE ' + @fk_table_name + ' DROP CONSTRAINT ' + @constraint_name) 
		
		FETCH NEXT FROM cc1 into @constraint_name, @fk_table_name
	end 
	CLOSE cc1 
	DEALLOCATE cc1 
END

DECLARE cc2 CURSOR fast_forward 
FOR 
SELECT CONSTRAINT_NAME
FROM INFORMATION_SCHEMA.CONSTRAINT_TABLE_USAGE 
WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = @table_name AND (@drop_pk = 1 OR CONSTRAINT_NAME <> @pk_name)

OPEN cc2
fETCH NEXT FROM cc2 INTO @constraint_name
WHILE @@fetch_status = 0 
BEGIN 
	SET @s = 'removing constraint: ' + @constraint_name
	PRINT @s
	
	EXEC('ALTER TABLE dbo.' + @table_name + ' DROP CONSTRAINT ' + @constraint_name) 
	
	FETCH NEXT FROM cc2 INTO @constraint_name
end 
CLOSE cc2
DEALLOCATE cc2
GO
