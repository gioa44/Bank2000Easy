SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  VIEW [impexp].[V_PORTIONS_OUT_SWIFT] AS

SELECT P.*, PS.NAME_GEO AS STATE_NAME_GEO, PS.NAME_LAT AS STATE_NAME_LAT, ISNULL(B.PORTION_ALIAS, P.PORTION) AS PORTION_ALIAS
FROM impexp.PORTIONS_OUT_SWIFT P
	INNER JOIN impexp.PORTION_STATES PS ON PS.STATE = P.STATE
	LEFT JOIN impexp.PORTIONS_OUT_SWIFT_INFO B ON B.PORTION = P.PORTION
GO
