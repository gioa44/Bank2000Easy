SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_fn_rep_get_before_annul_total_accrual_interest](@depo_id int)
--აბრუნდებს დარღვევამდე მთლიანად დარიცხულ პროცენტს
RETURNS money
AS
BEGIN
	DECLARE
		@result money,
		@op_data xml

	SELECT @op_data = OP_DATA
	FROM dbo.DEPO_OP (NOLOCK)
	WHERE DEPO_ID = @depo_id AND OP_TYPE IN (dbo.depo_fn_const_op_annulment(), dbo.depo_fn_const_op_annulment_amount(), dbo.depo_fn_const_op_annulment_positive(), dbo.depo_fn_const_op_close_default())

	SET @result = @op_data.value('(row/@TOTAL_CALC_AMOUNT)[1]', 'money')

	RETURN @result
END
GO
