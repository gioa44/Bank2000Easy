SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_GET_LOAN_CLIENT_BAL_ACC]
	@bal_acc TBAL_ACC OUTPUT,
	@client_no int,
	@start_date smalldatetime,
	@end_date smalldatetime,
	@iso TISO,
	@product_id int,
	@check_client_type bit = 0
AS
BEGIN
SET NOCOUNT ON;

SET @bal_acc = NULL

DECLARE
	@loan_bal_acc TBAL_ACC
	
EXEC dbo.LOAN_SP_GET_LOAN_BAL_ACC
	@bal_acc = @loan_bal_acc OUTPUT,
	@client_no = @client_no,
	@start_date = @start_date,
	@end_date = @end_date,
	@iso = @iso,
	@product_id = @product_id,
	@check_client_type = @check_client_type

IF @@ERROR <> 0
	RETURN 1
	

SELECT @bal_acc = ACCOUNT_BAL_ACC
FROM dbo.LOAN_CLIENT_BAL_ACCS (NOLOCK)
WHERE BAL_ACC = @loan_bal_acc

RETURN 0

END

GO
