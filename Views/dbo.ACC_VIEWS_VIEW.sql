SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[ACC_VIEWS_VIEW]
AS
SELECT w.ID, w.DESCRIP, w.[SCHEMA], w.NAME, w.[SYSTEM],
		CAST(m.definition AS varchar(MAX)) AS VIEW_CONTENT
FROM dbo.ACC_VIEWS (NOLOCK) w
INNER JOIN sys.objects o ON o.name = w.NAME
INNER JOIN sys.schemas s ON s.schema_id = o.schema_id AND s.name = w.[SCHEMA]
INNER JOIN sys.sql_modules m ON m.object_id = o.object_id
WHERE o.type = 'V' AND o.parent_object_id = 0
GO
