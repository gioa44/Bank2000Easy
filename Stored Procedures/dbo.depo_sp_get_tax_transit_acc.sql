SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_get_tax_transit_acc]
	@iso char(3),
	@tax_transit_acc_id int OUTPUT,
	@tax_transit_account TACCOUNT = NULL OUTPUT
AS

SET NOCOUNT ON;



DECLARE
	@tax_branch_id int

EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_TRANS_ACC', @tax_transit_account OUTPUT

EXEC dbo.GET_SETTING_INT 'HEAD_BRANCH_DEPT_NO ', @tax_branch_id OUTPUT

SET @tax_transit_acc_id = dbo.acc_get_acc_id (@tax_branch_id, @tax_transit_account, @iso)

RETURN 0

GO
