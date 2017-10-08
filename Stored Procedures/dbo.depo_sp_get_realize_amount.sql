SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_get_realize_amount]
	@acc_id int,
	@user_id int,
	@dept_no int,
	@doc_date smalldatetime,
	@calc_date smalldatetime
AS
SET NOCOUNT ON;

DECLARE
	@r int

DECLARE
	@depo_op_type int,
	@depo_amount money,
	@interest_amount money,
	@tax_rate money
	
DECLARE
	@depo_id int,
	@advance_amount money,
	@calc_amount money,
	@total_calc_amount money,
	@total_payed_amount money,
	@last_move_date smalldatetime,
	@total_tax_payed_amount money,
	@total_tax_payed_amount_equ money	
	
SELECT @calc_amount = ISNULL(CALC_AMOUNT, $0.00), @last_move_date = LAST_MOVE_DATE,	
	@total_calc_amount = ISNULL(TOTAL_CALC_AMOUNT, $0.00), @total_payed_amount = ISNULL(TOTAL_PAYED_AMOUNT, $0.00),
	@depo_id = DEPO_ID, @advance_amount = ISNULL(ADVANCE_AMOUNT, $0.00), @tax_rate = ISNULL(TAX_RATE, $0.00),
	@total_tax_payed_amount = ISNULL(TOTAL_TAX_PAYED_AMOUNT, $0.00), @total_tax_payed_amount_equ = ROUND(ISNULL(TOTAL_TAX_PAYED_AMOUNT_EQU, $0.00), 2)
FROM dbo.ACCOUNTS_CRED_PERC (NOLOCK)
WHERE ACC_ID = @acc_id
	

SET @depo_amount = - dbo.acc_get_balance(@acc_id, @calc_date, 0, 0, 1)
SET @depo_op_type = dbo.depo_fn_const_op_close();

EXEC @r = dbo.PROCESS_ACCRUAL
	@perc_type = 0,
	@acc_id = @acc_id,
	@user_id = @user_id,
	@dept_no = @dept_no,
	@doc_date = @doc_date,
	@calc_date = @calc_date,
	@force_realization = 1,
	@simulate = 1,
	@show_result = 0,
	@depo_depo_id = @depo_id,
	@depo_op_type = @depo_op_type,
	@interest_amount  = @interest_amount OUTPUT

SELECT @depo_amount AS DEPO_AMOUNT, @interest_amount AS INTEREST_AMOUNT,
	@calc_amount AS CALC_AMOUNT, @total_calc_amount AS TOTAL_CALC_AMOUNT, @total_payed_amount AS TOTAL_PAYED_AMOUNT, @last_move_date AS LAST_MOVE_DATE,
	@advance_amount AS ADVANCE_AMOUNT, @tax_rate AS TAX_RATE, @total_tax_payed_amount AS TOTAL_TAX_PAYED_AMOUNT, @total_tax_payed_amount_equ AS TOTAL_TAX_PAYED_AMOUNT_EQU


RETURN 0

GO
