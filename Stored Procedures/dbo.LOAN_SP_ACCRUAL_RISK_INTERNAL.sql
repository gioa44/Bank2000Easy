SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_ACCRUAL_RISK_INTERNAL]
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
	@risk_category_date				smalldatetime,
	@risk_category_1_balance		money,
	@risk_category_1_balance_		money,
	@risk_category_2_balance		money,
	@risk_category_2_balance_		money,
	@risk_category_3_balance		money,
	@risk_category_3_balance_		money,
	@risk_category_4_balance		money,
	@risk_category_4_balance_		money,
	@risk_category_5_balance		money,
	@risk_category_5_balance_		money,
	@risk_category_balance			money,
	@risk_category_balance_			money,
	@risk_accrue					money

EXEC @r = dbo.LOAN_SP_ACCRUAL_RISK
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
	@risk_category_date				= @risk_category_date OUTPUT,
	@risk_category_1_balance		= @risk_category_1_balance OUTPUT,
	@risk_category_1_balance_		= @risk_category_1_balance_ OUTPUT,
	@risk_category_2_balance		= @risk_category_2_balance OUTPUT,
	@risk_category_2_balance_		= @risk_category_2_balance_ OUTPUT,
	@risk_category_3_balance		= @risk_category_3_balance OUTPUT,
	@risk_category_3_balance_		= @risk_category_3_balance_ OUTPUT,
	@risk_category_4_balance		= @risk_category_4_balance OUTPUT,
	@risk_category_4_balance_		= @risk_category_4_balance_ OUTPUT,
	@risk_category_5_balance		= @risk_category_5_balance OUTPUT,
	@risk_category_5_balance_		= @risk_category_5_balance_ OUTPUT,
	@risk_category_balance			= @risk_category_balance OUTPUT,
	@risk_category_balance_			= @risk_category_balance_ OUTPUT,
	@risk_accrue					= @risk_accrue OUTPUT

IF @r <> 0 OR @@ERROR <> 0
BEGIN
	RAISERROR ('ÛÄÝÃÏÌÀ ÃÀÒÉÝáÅÉÓÀÓ!',16,1)
	RETURN 1
END

RETURN 0
GO
