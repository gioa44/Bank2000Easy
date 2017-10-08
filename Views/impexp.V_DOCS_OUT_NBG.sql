SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  VIEW [impexp].[V_DOCS_OUT_NBG] AS

SELECT A.*, P.STATE
FROM impexp.DOCS_OUT_NBG A
	INNER JOIN impexp.PORTIONS_OUT_NBG P(NOLOCK) ON P.PORTION_DATE = A.PORTION_DATE AND P.PORTION = A.PORTION
GO