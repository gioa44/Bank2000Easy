SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[FIND_IN_OBJECTS] @search_text nvarchar(4000)
AS
PRINT 'IN ALL SQL MODULES...'
SELECT O.[name] AS [OBJECT_NAME], O.type_desc, M.definition FROM sys.all_sql_modules M
INNER JOIN sys.all_objects O ON O.object_id = M.object_id
WHERE M.definition LIKE '%' + @search_text + '%'


PRINT 'IN VIEW...'
SELECT V.TABLE_NAME, V.VIEW_DEFINITION FROM INFORMATION_SCHEMA.VIEWS V
WHERE V.VIEW_DEFINITION LIKE '%' + @search_text + '%'

PRINT 'IN PARAMETERS...'
SELECT O.[name]AS [OBJECT_NAME], P.* FROM sys.all_parameters P
INNER JOIN sys.all_objects O ON O.object_id = P.object_id
WHERE P.[name] LIKE '%' + @search_text + '%'

PRINT 'IN COLUMNS...'
SELECT O.[name] AS [OBJECT_NAME], C.* FROM sys.all_columns C
INNER JOIN sys.all_objects O ON O.object_id = C.object_id
WHERE C.[name] LIKE '%' + @search_text + '%'

GO
