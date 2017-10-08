SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[LOAN_SP_GET_GUAR_CLI_BAL_ACC]
	@bal_acc TBAL_ACC OUTPUT,
	@client_no int,
	@iso TISO
AS
SET NOCOUNT ON;

SET @bal_acc = NULL

DECLARE
	@guarantee_bal_acc TBAL_ACC

EXEC dbo.LOAN_SP_GET_GUARANTEE_BAL_ACC
	@bal_acc = @guarantee_bal_acc OUTPUT,
	@client_no = @client_no,
	@iso = @iso

IF @@ERROR <> 0
	RETURN 1
	
SELECT @bal_acc = ACCOUNT_BAL_ACC
FROM dbo.LOAN_CLIENT_BAL_ACCS (NOLOCK)
WHERE BAL_ACC = @guarantee_bal_acc


RETURN 0

GO
