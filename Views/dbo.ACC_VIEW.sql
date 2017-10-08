SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[ACC_VIEW] AS

SELECT 
	A.*, 
	D.SALDO,
	D.SHADOW_DBO, 
	D.SHADOW_CRO, 
	D.SALDO_AVAILABLE, 
	D.LAST_OP_DATE, 
	D.AMOUNT_KAS_DELTA,
	D.UID2
FROM dbo.ACCOUNTS A (NOLOCK)
  INNER JOIN  dbo.ACCOUNTS_DETAILS D (NOLOCK) ON A.ACC_ID = D.ACC_ID
GO
