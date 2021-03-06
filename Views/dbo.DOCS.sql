SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DOCS] AS

SELECT D.*, AD.ACCOUNT AS DEBIT, AC.ACCOUNT AS CREDIT
FROM dbo.OPS_0000 D
 INNER JOIN dbo.ACCOUNTS AD ON AD.ACC_ID = D.DEBIT_ID
 INNER JOIN dbo.ACCOUNTS AC ON AC.ACC_ID = D.CREDIT_ID
GO
