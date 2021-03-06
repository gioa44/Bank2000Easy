SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[TCD_VW_TCD_INFO]
AS
	SELECT D.CITY, D.DESCRIP AS DEPT_DESCRIP, D.ADDRESS,

	ISNULL(T.IP_ADDRESS, '') AS IP_ADDRESS,
	ISNULL(T.CASETTE_TOTAL_COUNT, 0) AS CASETTE_TOTAL_COUNT,
	ISNULL(T.TCD_SERIAL_ID, 0) AS TCD_SERIAL_ID,
	ISNULL(T.STATE, '') AS [STATE],

	ISNULL(T.CASETTE_SER_ID_1, -1) AS CASETTE_SER_ID_1,
	ISNULL(T.CASETTE_SER_ID_2, -1) AS CASETTE_SER_ID_2,
	ISNULL(T.CASETTE_SER_ID_3, -1) AS CASETTE_SER_ID_3,
	ISNULL(T.CASETTE_SER_ID_4, -1) AS CASETTE_SER_ID_4,
	ISNULL(T.CASETTE_SER_ID_5, -1) AS CASETTE_SER_ID_5,
	ISNULL(T.CASETTE_SER_ID_6, -1) AS CASETTE_SER_ID_6,

	ISNULL(T.CASETTE_STATE_1, -1) AS CASETTE_STATE_1,
	ISNULL(T.CASETTE_STATE_2, -1) AS CASETTE_STATE_2,
	ISNULL(T.CASETTE_STATE_3, -1) AS CASETTE_STATE_3,
	ISNULL(T.CASETTE_STATE_4, -1) AS CASETTE_STATE_4,
	ISNULL(T.CASETTE_STATE_5, -1) AS CASETTE_STATE_5,
	ISNULL(T.CASETTE_STATE_6, -1) AS CASETTE_STATE_6,

	ISNULL(T.CASETTE_CCY_1, '*') AS CASETTE_CCY_1,
	ISNULL(T.CASETTE_CCY_2, '*') AS CASETTE_CCY_2,
	ISNULL(T.CASETTE_CCY_3, '*') AS CASETTE_CCY_3,
	ISNULL(T.CASETTE_CCY_4, '*') AS CASETTE_CCY_4,
	ISNULL(T.CASETTE_CCY_5, '*') AS CASETTE_CCY_5,
	ISNULL(T.CASETTE_CCY_6, '*') AS CASETTE_CCY_6,

	ISNULL(T.CASETTE_QUANT_1, 0) AS CASETTE_QUANT_1,
	ISNULL(T.CASETTE_QUANT_2, 0) AS CASETTE_QUANT_2,
	ISNULL(T.CASETTE_QUANT_3, 0) AS CASETTE_QUANT_3,
	ISNULL(T.CASETTE_QUANT_4, 0) AS CASETTE_QUANT_4,
	ISNULL(T.CASETTE_QUANT_5, 0) AS CASETTE_QUANT_5,
	ISNULL(T.CASETTE_QUANT_6, 0) AS CASETTE_QUANT_6,

	ISNULL(T.CASETTE_DEN_1, 0) AS CASETTE_DEN_1,
	ISNULL(T.CASETTE_DEN_2, 0) AS CASETTE_DEN_2,
	ISNULL(T.CASETTE_DEN_3, 0) AS CASETTE_DEN_3,
	ISNULL(T.CASETTE_DEN_4, 0) AS CASETTE_DEN_4,
	ISNULL(T.CASETTE_DEN_5, 0) AS CASETTE_DEN_5,
	ISNULL(T.CASETTE_DEN_6, 0) AS CASETTE_DEN_6,

	ISNULL(T.CASETTE_DEN_1, $0.00) * ISNULL(CASETTE_QUANT_1, $0.00) AS SUM_1,
	ISNULL(T.CASETTE_DEN_2, $0.00) * ISNULL(CASETTE_QUANT_2, $0.00) AS SUM_2,
	ISNULL(T.CASETTE_DEN_3, $0.00) * ISNULL(CASETTE_QUANT_3, $0.00) AS SUM_3,
	ISNULL(T.CASETTE_DEN_4, $0.00) * ISNULL(CASETTE_QUANT_4, $0.00) AS SUM_4,
	ISNULL(T.CASETTE_DEN_5, $0.00) * ISNULL(CASETTE_QUANT_5, $0.00) AS SUM_5,
	ISNULL(T.CASETTE_DEN_6, $0.00) * ISNULL(CASETTE_QUANT_6, $0.00) AS SUM_6
	FROM dbo.TCDS T (NOLOCK)
	  INNER JOIN  dbo.DEPTS D (NOLOCK) ON D.DEPT_NO = T.DEPT_NO
GO
