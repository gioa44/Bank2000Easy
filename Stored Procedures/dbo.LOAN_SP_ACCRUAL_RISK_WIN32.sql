SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_ACCRUAL_RISK_WIN32]
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
	@doc_date						= @doc_date,
	@loan_id						= @loan_id,
	@user_id						= @user_id,
	@return_params					= @return_params,
	@create_table					= @create_table,
	@simulate						= @simulate,
	@select_list					= @select_list,
	@accrue							= @accrue,
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

IF @return_params = 1
BEGIN
	SELECT @doc_rec_id AS DOC_REC_ID, @risk_category_date AS RISK_CATEGORY_DATE,
		@risk_category_1_balance AS RISK_CATEGORY_1_BALANCE, @risk_category_1_balance_ AS RISK_CATEGORY_1_BALANCE_,
		@risk_category_2_balance AS RISK_CATEGORY_2_BALANCE, @risk_category_2_balance_ AS RISK_CATEGORY_2_BALANCE_,
		@risk_category_3_balance AS RISK_CATEGORY_3_BALANCE, @risk_category_3_balance_ AS RISK_CATEGORY_3_BALANCE_,
		@risk_category_4_balance AS RISK_CATEGORY_4_BALANCE, @risk_category_4_balance_ AS RISK_CATEGORY_4_BALANCE_,
		@risk_category_5_balance AS RISK_CATEGORY_5_BALANCE, @risk_category_5_balance_ AS RISK_CATEGORY_5_BALANCE_,
		@risk_category_balance AS RISK_CATEGORY_BALANCE, @risk_category_balance_ AS RISK_CATEGORY_BALANCE_,
		@risk_accrue AS RISK_ACCRUE
	RETURN 0
END

IF @select_list = 0
	SELECT 0 AS RESULT

RETURN 0
GO
