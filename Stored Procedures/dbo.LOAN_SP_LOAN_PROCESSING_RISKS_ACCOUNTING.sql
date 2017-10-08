SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_LOAN_PROCESSING_RISKS_ACCOUNTING]
	@date smalldatetime,
	@user_id int
AS
SET NOCOUNT ON

DECLARE
	@r int

DECLARE
	@loan_id int


DECLARE cr CURSOR LOCAL FORWARD_ONLY FAST_FORWARD READ_ONLY 
FOR SELECT LOAN_ID
FROM dbo.LOANS

OPEN cr

FETCH NEXT FROM cr INTO @loan_id

WHILE @@FETCH_STATUS = 0
BEGIN

	EXEC @r = dbo.LOAN_SP_ACCRUAL_RISK_INTERNAL
		@accrue_date					= @date,
		@loan_id						= @loan_id,
		@user_id						= @user_id,
		@create_table					= 1,
		@simulate						= 0

	IF @@ERROR<>0 OR @r<>0 GOTO _ret_error 

	FETCH NEXT FROM cr INTO @loan_id
END

CLOSE cr
DEALLOCATE cr
RETURN 0

_ret_error:
CLOSE cr
DEALLOCATE cr
RETURN 1
GO
