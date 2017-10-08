SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_get_tax_revert_acc]
	@iso char(3),
	@tax_revert_acc_id int OUTPUT,
	@tax_revert_account TACCOUNT = NULL OUTPUT
AS

SET NOCOUNT ON;


DECLARE
	@tax_branch_id int

IF @iso = 'GEL'
	EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_REVERT_ACC', @tax_revert_account OUTPUT
ELSE
	EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_REVERT_ACCV', @tax_revert_account OUTPUT

EXEC dbo.GET_SETTING_INT 'HEAD_BRANCH_DEPT_NO ', @tax_branch_id OUTPUT

SET @tax_revert_acc_id = dbo.acc_get_acc_id (@tax_branch_id, @tax_revert_account, @iso)

RETURN 0

GO
