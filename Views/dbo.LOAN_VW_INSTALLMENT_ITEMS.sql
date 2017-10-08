SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[LOAN_VW_INSTALLMENT_ITEMS]
AS
SELECT I.LOAN_ID, I.ITEM_ID, C.DESCRIP AS COLLATERAL_DESCRIP, C.DESCRIP_LAT AS COLLATERAL_DESCRIP_LAT,
	I.DESCRIP, I.DESCRIP_LAT, I.ITEM_PRICE
FROM dbo.LOAN_INSTALLMENT_ITEMS I
	INNER JOIN dbo.LOAN_COLLATERAL_ITEMS C ON I.ITEM_ID = C.ITEM_ID
WHERE C.INSTALLMENT = 1
GO
