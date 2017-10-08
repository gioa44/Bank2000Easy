SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[LOAN_SP_ACCRUAL_INTEREST_WIN32]
/*
1. ÃÀÀÁÒÖÍÏÓ ÐÀÒÀÌÄÔÒÄÁÛÉ ÃÀÒÉÝáÅÉÓ ÌÏÍÀÝÄÌÄÁÉ -> @return_params
2. ÛÄØÌÍÀÓ ÃÏÊÖÌÄÍÔÄÁÉÓ ÓÉÀ -> @create_table
3. ÛÄÀÅÓÏÓ ÃÏÊÖÌÄÍÔÄÁÉÓ ÓÉÀ -> @return_params == FALSE
4. ÃÀÀÌÀÔÏÓ ÓÀÁÖÈÄÁÉ ÀÍ ÂÀÀÊÄÈÏÓ ÓÉÌÖËÀÝÉÀ -> @simulate
5. ÃÀÀÓÄËÄØÔÏÓ ÃÏÊÖÌÄÍÔÄÁÉÓ ÓÉÀ -> @select_list
6. ÀÒ ÂÀÀÊÄÈÏÓ ÀÒÀ×ÄÒÉ -> @accrue
*/

	@accrue_date					smalldatetime,
	@doc_date						smalldatetime,
	@loan_id						int,
	@user_id						int,
	@return_params					bit = 0,
	@create_table					bit = 1,
	@simulate						bit = 0,
	@select_list					bit = 0,
	@accrue							bit = 1
AS
SET NOCOUNT ON

DECLARE
	@r int

DECLARE
	@doc_rec_id						int,
	@interest_date					smalldatetime,
	@interest_balance				money,
	@interest_balance_				money,
	@interest2accrue				money,
	@overdue_interest_date			smalldatetime,
	@overdue_interest_balance		money,
	@overdue_interest30_date		smalldatetime,
	@overdue_interest30_balance		money,
	@overdue_interest30_balance_	money,
	@overdue_interest302accrue		money,
	@penalty_date					smalldatetime,
	@penalty_balance				money,
	@penalty_balance_				money,
	@penalty2accrue					money,
	@writeoff_date					smalldatetime,
	@writeoff_balance				money,
	@writeoff_balance_				money,
	@writeoff2accrue				money

EXEC @r = dbo.LOAN_SP_ACCRUAL_INTEREST
	@doc_rec_id						= @doc_rec_id OUTPUT,
	@accrue_date					= @accrue_date,
	@doc_date						= @doc_date,
	@loan_id						= @loan_id,
	@user_id						= @user_id,
	@return_params					= @return_params,
	@create_table					= @create_table,
	@simulate						= @simulate,
	@select_list					= @select_list,
	@accrue							= @accrue,
	@interest_date					= @interest_date				OUTPUT,
	@interest_balance				= @interest_balance				OUTPUT,
	@interest_balance_				= @interest_balance_			OUTPUT,
	@interest2accrue				= @interest2accrue				OUTPUT,
	@overdue_interest_date			= @overdue_interest_date		OUTPUT,
	@overdue_interest_balance		= @overdue_interest_balance		OUTPUT,
	@overdue_interest30_date		= @overdue_interest30_date		OUTPUT,
	@overdue_interest30_balance		= @overdue_interest30_balance	OUTPUT,
	@overdue_interest30_balance_	= @overdue_interest30_balance_	OUTPUT,
	@overdue_interest302accrue		= @overdue_interest302accrue	OUTPUT,
	@penalty_date					= @penalty_date					OUTPUT,
	@penalty_balance				= @penalty_balance				OUTPUT,
	@penalty_balance_				= @penalty_balance_				OUTPUT,
	@penalty2accrue					= @penalty2accrue				OUTPUT,
	@writeoff_date					= @writeoff_date				OUTPUT,
	@writeoff_balance				= @writeoff_balance				OUTPUT,
	@writeoff_balance_				= @writeoff_balance_			OUTPUT,
	@writeoff2accrue				= @writeoff2accrue				OUTPUT
IF @r <> 0 OR @@ERROR <> 0
BEGIN
	RAISERROR ('ÛÄÝÃÏÌÀ ÃÀÒÉÝáÅÉÓÀÓ!',16,1)
	RETURN 1
END

IF @return_params = 1
BEGIN
	SELECT @doc_rec_id AS DOC_REC_ID,
		@interest_date AS INTEREST_DATE, @interest_balance AS INTEREST_BALANCE, @interest_balance_ AS INTEREST_BALANCE_, @interest2accrue AS INTEREST2ACCRUE,
		@overdue_interest_date AS OVERDUE_INTEREST_DATE, @overdue_interest_balance AS OVERDUE_INTEREST_BALANCE,
		@overdue_interest30_date AS OVERDUE_INTEREST30_DATE, @overdue_interest30_balance AS OVERDUE_INTEREST30_BALANCE, @overdue_interest30_balance_ AS OVERDUE_INTEREST30_BALANCE_, @overdue_interest302accrue AS OVERDUE_INTEREST302ACCRUE,
		@penalty_date AS PENALTY_DATE, @penalty_balance AS PENALTY_BALANCE, @penalty_balance_ AS PENALTY_BALANCE_, @penalty2accrue AS PENALTY2ACCRUE,
		@writeoff_date	AS WRITEOFF_DATE, @writeoff_balance AS WRITEOFF_BALANCE, @writeoff_balance_	AS WRITEOFF_BALANCE_, @writeoff2accrue AS WRITEOFF2ACCRUE,
		@interest2accrue + @overdue_interest302accrue + @penalty2accrue + @writeoff2accrue AS INTEREST_ACCRUE
		

	RETURN 0
END

IF @select_list = 0
	SELECT 0 AS RESULT

RETURN 0
GO
