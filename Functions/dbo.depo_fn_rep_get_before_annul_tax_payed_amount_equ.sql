SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_fn_rep_get_before_annul_tax_payed_amount_equ](@depo_id int)
--აბრუნდებს დარღვევამდე დაბეგრილ პროცენტების ექვივალენტს ლარში, დაბეგრის დროს დაფიქსირებული კურსის გათვალისწინებით
RETURNS money
AS
BEGIN
	DECLARE
		@result money,
		@op_data xml

	SELECT @op_data = OP_DATA
	FROM dbo.DEPO_OP (NOLOCK)
	WHERE DEPO_ID = @depo_id AND OP_TYPE IN (dbo.depo_fn_const_op_annulment(), dbo.depo_fn_const_op_annulment_amount(), dbo.depo_fn_const_op_annulment_positive(), dbo.depo_fn_const_op_close_default())

	SET @result = @op_data.value('(row/@TOTAL_TAX_PAYED_AMOUNT_EQU)[1]', 'money')

	RETURN @result
END
GO
