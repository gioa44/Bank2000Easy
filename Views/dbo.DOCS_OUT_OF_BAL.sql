SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DOCS_OUT_OF_BAL] AS

SELECT D.*
FROM dbo.DOCS_ALL D
WHERE D.DOC_TYPE BETWEEN 200 AND 249
GO
