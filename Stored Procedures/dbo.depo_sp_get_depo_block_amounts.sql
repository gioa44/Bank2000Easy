SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_get_depo_block_amounts]
	@depo_acc_id int,
	@depo_id int,
	@block_id int = NULL
AS
SET NOCOUNT ON;


IF @block_id IS NULL
	SELECT *
	FROM dbo.acc_accounts_blocks
	WHERE ACC_ID = @depo_acc_id AND USER_DATA = @depo_id AND IS_ACTIVE = 1 AND BLOCKED_BY_PRODUCT = '#DEPOSIT'
ELSE
	SELECT *
	FROM dbo.acc_accounts_blocks
	WHERE BLOCK_ID = @block_id

GO
