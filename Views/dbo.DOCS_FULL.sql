SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DOCS_FULL] AS

SELECT *
FROM dbo.DOCS

UNION ALL

SELECT *
FROM dbo.DOCS_ARC
GO