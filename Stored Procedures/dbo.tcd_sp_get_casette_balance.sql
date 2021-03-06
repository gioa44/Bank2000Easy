SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tcd_sp_get_casette_balance]
AS
BEGIN
	SELECT CASETTE_CCY_1 AS CASETTE_CCY, (CASETTE_DEN_1 * CASETTE_QUANT_1) AS AMOUNT FROM dbo.TCDS WHERE CASETTE_STATE_1 = 0
	UNION
	SELECT CASETTE_CCY_2 AS CASETTE_CCY, (CASETTE_DEN_2 * CASETTE_QUANT_2) AS AMOUNT FROM dbo.TCDS WHERE CASETTE_STATE_2 = 0
	UNION
	SELECT CASETTE_CCY_3 AS CASETTE_CCY, (CASETTE_DEN_3 * CASETTE_QUANT_3) AS AMOUNT FROM dbo.TCDS WHERE CASETTE_STATE_3 = 0
	UNION
	SELECT CASETTE_CCY_4 AS CASETTE_CCY, (CASETTE_DEN_4 * CASETTE_QUANT_4) AS AMOUNT FROM dbo.TCDS WHERE CASETTE_STATE_4 = 0
	UNION
	SELECT CASETTE_CCY_5 AS CASETTE_CCY, (CASETTE_DEN_5 * CASETTE_QUANT_5) AS AMOUNT FROM dbo.TCDS WHERE CASETTE_STATE_5 = 0
	UNION
	SELECT CASETTE_CCY_6 AS CASETTE_CCY, (CASETTE_DEN_6 * CASETTE_QUANT_6) AS AMOUNT FROM dbo.TCDS WHERE CASETTE_STATE_6 = 0
END
GO
