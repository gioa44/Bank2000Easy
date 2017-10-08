SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_GET_OP_AMOUNT]
  @loan_id int, 
  @date smalldatetime, 
  @op_type smallint
AS
SET NOCOUNT ON

DECLARE
	@amount money
SET @amount = $0.00

IF @op_type = dbo.loan_const_op_disburse() -- ÓÄÓáÉÓ ÂÀÝÄÌÀ
BEGIN
	SELECT @amount = DISBURSE_AMOUNT 
	FROM dbo.LOANS (NOLOCK)
	WHERE LOAN_ID = @loan_id
END
ELSE
IF @op_type = dbo.loan_const_op_overdue_revert()  -- ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÓÄÓáÉÓ ÒÄÊËÀÓÉ×ÉÊÀÝÉÀ ÒÏÂÏÒÝ ÜÅÄÖËÄÁÒÉÅÉÓÀ
BEGIN
	SELECT @amount = ISNULL(OVERDUE_PRINCIPAL_BALANCE, $0.00)
	FROM dbo.LOAN_ACCOUNT_BALANCE
	WHERE LOAN_ID = @loan_id
END

SELECT @amount AS AMOUNT

RETURN
GO
