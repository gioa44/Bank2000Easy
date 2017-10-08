SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_ACCRUAL_INTEREST_INTERNAL]
	@accrue_date					smalldatetime,
	@loan_id						int,
	@user_id						int,
	@create_table					bit,
	@simulate						bit
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
	@doc_date						= @accrue_date,
	@loan_id						= @loan_id,
	@user_id						= @user_id,
	@return_params					= 0,
	@create_table					= @create_table,
	@simulate						= @simulate,
	@select_list					= 0,
	@accrue							= 1,
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

RETURN 0


GO
