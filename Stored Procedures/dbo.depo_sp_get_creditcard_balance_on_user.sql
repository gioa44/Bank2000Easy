SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_get_creditcard_balance_on_user]
	@depo_id int,
	@acc_id int,
	@creditcard_balance money OUTPUT
AS
BEGIN
	SET @creditcard_balance = NULL
	
	RETURN 0
END

GO
