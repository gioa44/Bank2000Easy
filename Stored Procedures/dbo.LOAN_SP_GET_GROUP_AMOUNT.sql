SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_GET_GROUP_AMOUNT]
	@group_id int
AS

DECLARE
	@group_limit_amount money,
	@group_iso TISO,
	@group_disbursed_amount money

	SELECT @group_limit_amount = LOAN_LIMIT_AMOUNT, @group_iso = LOAN_LIMIT_ISO
	FROM dbo.LOAN_GROUPS 
	WHERE GROUP_ID = @group_id

	SELECT @group_disbursed_amount = SUM(dbo.get_cross_amount(AMOUNT, ISO, @group_iso, dbo.loan_open_date()))
	FROM dbo.LOANS 
	WHERE GROUP_ID = @group_id AND STATE <> dbo.loan_const_state_closed()

	SELECT 
		@group_id AS GROUP_ID,
		@group_limit_amount AS GROUP_LIMIT_AMOUNT,
		@group_iso AS GROUP_ISO,
		ISNULL(@group_disbursed_amount, $0.00) AS GROUP_DISBURSED_AMOUNT


	RETURN



GO
