SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [impexp].[DOCS_OUT_SWIFT_FULL]
AS

SELECT * FROM impexp.DOCS_OUT_SWIFT

UNION ALL

SELECT * FROM impexp.DOCS_OUT_SWIFT_ARC
GO
