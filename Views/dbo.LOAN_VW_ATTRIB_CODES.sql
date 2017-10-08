SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[LOAN_VW_ATTRIB_CODES]
AS
SELECT CODE, CONVERT(int, NULL) AS PRODUCT_ID, DESCRIP, DESCRIP_LAT, IS_REQUIRED, ONLY_ONE_VALUE, TYPE, [VALUES]
FROM dbo.LOAN_ATTRIB_CODES (NOLOCK)
WHERE IS_COMMON = 1
UNION
SELECT A.CODE, P.PRODUCT_ID, A.DESCRIP, A.DESCRIP_LAT, P.IS_REQUIRED, A.ONLY_ONE_VALUE, A.TYPE, A.[VALUES]
FROM dbo.LOAN_ATTRIB_CODES A (NOLOCK)
	INNER JOIN dbo.LOAN_PRODUCT_ATTRIB_CODES P (NOLOCK) ON A.CODE = P.CODE
WHERE A.IS_COMMON = 0
GO
