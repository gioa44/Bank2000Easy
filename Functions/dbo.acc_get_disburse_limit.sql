SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[acc_get_disburse_limit](
	  @acc_id int, 		
	  @date smalldatetime
)		
RETURNS money AS		
BEGIN		
	DECLARE
		@approved_limit money,	
		@disburse_limit money,
		@balance money,
		@balance_0000 money

	SET @disburse_limit = $0.00	
	SET @approved_limit = -dbo.acc_get_min_amount(@acc_id, @date)

	SELECT @balance = A.SALDO	
	FROM dbo.ACCOUNTS_DETAILS A (NOLOCK)	
	WHERE A.ACC_ID = @acc_id	

	SET @balance = ISNULL(@balance, $0.00)	

	SELECT @balance_0000 = SUM(CASE @acc_id WHEN D.DEBIT_ID THEN D.AMOUNT ELSE $0.00 END) - SUM(CASE @acc_id WHEN D.CREDIT_ID THEN D.AMOUNT ELSE $0.00 END)	
	FROM dbo.OPS_HELPER_0000 S(NOLOCK) 	
		INNER JOIN dbo.OPS_0000 D(NOLOCK) ON D.REC_ID = S.REC_ID
	WHERE S.ACC_ID = @acc_id AND S.DT <= @date AND D.REC_STATE >= 0	

	SET @balance = @balance + ISNULL(@balance_0000, $0.00)	
	
	IF @balance <= $0.00	
		SET @disburse_limit =  $0.00
	ELSE	
		SET @disburse_limit = CASE WHEN (@approved_limit > @balance) THEN @balance ELSE @approved_limit END

	RETURN ISNULL(@disburse_limit, $0.00)	
END		
GO
