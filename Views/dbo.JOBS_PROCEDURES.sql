SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  VIEW [dbo].[JOBS_PROCEDURES]
AS

SELECT name AS DESCRIP
FROM dbo.sysobjects obj
WHERE (xtype = 'P') AND (name LIKE 'JOB!_%' ESCAPE '!') AND
  EXISTS (SELECT * FROM syscolumns col, systypes typ WHERE obj.id = col.id AND col.colid = 1 AND col.xusertype = typ.xusertype AND typ.name = 'int')
GO
