SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_get_depo_acc_usable_amount]
	@depo_acc_id int
AS
SET NOCOUNT ON;

DECLARE
	@usable_amount money

EXEC dbo.acc_get_usable_amount
	@acc_id = @depo_acc_id,
	@usable_amount = @usable_amount OUTPUT,
	@use_overdraft = 0

SELECT @usable_amount AS USABLE_AMOUNT

GO
