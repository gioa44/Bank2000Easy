SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[LOAN_VW_COLLATERAL_ACCOUNT_TEMPLATES]
AS
SELECT T.TYPE_ID, T.CODE AS COLLATERAL_CODE, T.CODE_LAT AS COLLATERAL_CODE_LAT, T.DESCRIP AS COLLATERAL_DESCRIP, T.DESCRIP_LAT AS COLLATERAL_DESCRIP_LAT, A.COLLATERAL_TYPE, A.BAL_ACC, P.DESCRIP AS BAL_ACC_DESCRIP, P.DESCRIP_LAT AS BAL_ACC_DESCRIP_LAT, A.TEMPLATE
FROM dbo.LOAN_COLLATERAL_TYPES T (NOLOCK)
	LEFT OUTER JOIN dbo.LOAN_COLLATERAL_ACCOUNT_TEMPLATES A (NOLOCK) ON A.COLLATERAL_TYPE = T.TYPE_ID
	LEFT OUTER JOIN dbo.PLANLIST_ALT P (NOLOCK) ON P.BAL_ACC = A.BAL_ACC
GO
