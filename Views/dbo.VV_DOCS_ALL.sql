SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE VIEW [dbo].[VV_DOCS_ALL] AS

SELECT * FROM DOCS

UNION ALL

SELECT * FROM DOCS_ARC


GO
