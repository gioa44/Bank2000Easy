SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[LOAN_VW_INSTALLMENT_CLIENTS]
AS
	SELECT C.CLIENT_NO, C.DESCRIP, C.DESCRIP_LAT, I.INTEREST_TYPE, I.STEP_COUNT, I.INTRATE, I.IS_ACTIVE
	FROM dbo.LOAN_INSTALLMENT_CLIENTS AS I INNER JOIN
		dbo.CLIENTS AS C ON I.CLIENT_NO = C.CLIENT_NO
GO
