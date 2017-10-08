SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[LOAN_VW_INSTALLMENT_CLIENT_LIST]
AS
	SELECT C.*
	FROM dbo.CLIENTS C (NOLOCK)
		INNER JOIN dbo.LOAN_INSTALLMENT_CLIENTS I (NOLOCK) ON I.CLIENT_NO = C.CLIENT_NO
	WHERE I.IS_ACTIVE = 1
GO