SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_get_tax_acc]
	@iso char(3),
	@client_no int,
	@is_juridical bit = NULL,
	@is_resident bit = NULL,
	@tax_acc_id int OUTPUT,
	@tax_account TACCOUNT = NULL OUTPUT,
	@tax_equ_acc_id int = NULL OUTPUT
AS

SET NOCOUNT ON;


IF (@is_juridical IS NULL) OR (@is_resident IS NULL)
	SELECT @is_juridical = IS_JURIDICAL, @is_resident = IS_RESIDENT
	FROM dbo.CLIENTS (NOLOCK)
	WHERE CLIENT_NO = @client_no


DECLARE
	@tax_branch_id int,
	@tax_equ_account TACCOUNT

IF @iso = 'GEL'
BEGIN
	IF @client_no IS NULL
		EXEC dbo.GET_SETTING_ACC 'DEPOSIT_TAX_ACC', @tax_account OUTPUT
	ELSE
	IF @is_juridical = 0 AND @is_resident = 1
		EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_ACC_RP', @tax_account OUTPUT
	ELSE
	IF @is_juridical = 0 AND @is_resident = 0
		EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_ACC_NRP', @tax_account OUTPUT
	ELSE
	IF @is_juridical = 1 AND @is_resident = 1
		EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_ACC_RJ', @tax_account OUTPUT
	ELSE
	IF @is_juridical = 1 AND @is_resident = 0
		EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_ACC_NRJ', @tax_account OUTPUT
END
ELSE
BEGIN
	IF @client_no IS NULL
		EXEC dbo.GET_SETTING_ACC 'DEPOSIT_TAX_ACC_V', @tax_account OUTPUT
	ELSE
	IF @is_juridical = 0 AND @is_resident = 1
		EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_ACC_RP_V', @tax_account OUTPUT
	ELSE
	IF @is_juridical = 0 AND @is_resident = 0
		EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_ACC_NRP_V', @tax_account OUTPUT
	ELSE
	IF @is_juridical = 1 AND @is_resident = 1
		EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_ACC_RJ_V', @tax_account OUTPUT
	ELSE
	IF @is_juridical = 1 AND @is_resident = 0
		EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_ACC_NRJ_V', @tax_account OUTPUT
END

EXEC dbo.GET_SETTING_INT 'HEAD_BRANCH_DEPT_NO ', @tax_branch_id OUTPUT

SET @tax_acc_id = dbo.acc_get_acc_id (@tax_branch_id, @tax_account, @iso)

IF (@tax_acc_id IS NOT NULL) AND (@iso <> 'GEL')
BEGIN
	SELECT @tax_equ_account = PROF_LOSS_ACC FROM dbo.ACCOUNTS (NOLOCK) WHERE ACC_ID = @tax_acc_id

	IF @tax_equ_account IS NOT NULL
		SET @tax_equ_acc_id = dbo.acc_get_acc_id (@tax_branch_id, @tax_equ_account, 'GEL')
	ELSE
		SET @tax_equ_acc_id = dbo.acc_get_acc_id (@tax_branch_id, @tax_account, 'GEL')	
END
ELSE
	SET @tax_equ_acc_id = @tax_acc_id

RETURN 0

GO
