SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_get_creditcard_balance]
	@depo_id int,
	@acc_id int
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE
		@r int
		
	DECLARE
		@creditcard_balance money

	SET @creditcard_balance = NULL
	
	EXEC @r = dbo.depo_sp_get_creditcard_balance_on_user
		@depo_id = @depo_id,
		@acc_id = @acc_id,
		@creditcard_balance = @creditcard_balance OUTPUT
		
	IF @@ERROR <> 0 OR @r <> 0
		SET @creditcard_balance = $0.00
		
	SELECT @creditcard_balance AS CREDITCARD_BALANCE
	
END

GO
