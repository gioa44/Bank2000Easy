SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[TRANSACTIONS_OF_ACCOUNT_ACCRUALS] (@acc_id int)
AS

SELECT * 
FROM dbo.acc_show_cred_accruals (@acc_id) 
GO