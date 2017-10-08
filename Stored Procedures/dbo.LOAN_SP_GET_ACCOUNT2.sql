SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[LOAN_SP_GET_ACCOUNT2]
	@acc_id			int OUTPUT,
	@account		TACCOUNT OUTPUT,
	@acc_added		bit OUTPUT,
	@bal_acc		TBAL_ACC OUTPUT,
	@type_id		int,
	@credit_line_id	int,
	@iso			TISO = NULL,
	@user_id		int,
	@simulate		bit = 1,
	@guarantee		bit = 0	
AS
SET NOCOUNT ON
SET @acc_added = 0

DECLARE
	@account_iso TISO

SET @acc_id = NULL
SET @account = NULL
SET @account_iso = NULL

SELECT @acc_id = ACC_ID FROM dbo.LOAN_CREDIT_LINE_ACCOUNTS (NOLOCK) WHERE CREDIT_LINE_ID = @credit_line_id AND ACCOUNT_TYPE = @type_id

IF @acc_id IS NOT NULL
BEGIN
	SELECT @account = ACCOUNT, @bal_acc = BAL_ACC_ALT FROM dbo.ACCOUNTS (NOLOCK) WHERE ACC_ID = @acc_id
	RETURN 0
END


DECLARE
	@credit_line_iso	TISO,
	@branch_id			int,
	@dept_no			int,
	@client_no			int,
	@account_client_no	int,
	@agreement_no		varchar(100)

DECLARE
	@credit_line_no int

SELECT
	@branch_id			= BRANCH_NO,
	@dept_no			= DEPT_NO,
	@client_no			= CLIENT_NO,
	@credit_line_iso	= ISO,
	@agreement_no		= AGREEMENT_NO	
FROM dbo.LOAN_CREDIT_LINES (NOLOCK)
WHERE CREDIT_LINE_ID = @credit_line_id

SELECT @credit_line_no = COUNT(*)
FROM dbo.LOAN_CREDIT_LINES (NOLOCK)
WHERE CLIENT_NO = @client_no AND CREDIT_LINE_ID < @credit_line_id

SET @credit_line_no = ISNULL(@credit_line_no, 0) + 1

DECLARE
	@client_descrip		varchar(150),
	@client_descrip_lat	varchar(150)

SELECT @client_descrip = DESCRIP, @client_descrip_lat = DESCRIP_LAT
FROM dbo.CLIENTS (NOLOCK)
WHERE CLIENT_NO = @client_no

DECLARE
	@account_type_descrip varchar(150)

DECLARE
	@template varchar(150),
	@parent_acc_type_id	int


IF @type_id BETWEEN 10001 AND 10010
BEGIN
	SELECT @template = TEMPLATE
	FROM dbo.LOAN_CREDIT_LINE_ACCOUNT_TEMPLATES (NOLOCK)
	WHERE COLLATERAL_TYPE = @type_id - 10000
END

DECLARE
	@r int,
	@bal_acc_alt TBAL_ACC,  
	@own_account bit,
	@fixed_account bit

SET @own_account = 0
SET @fixed_account = 0

IF (CHARINDEX('N', @template) <> 0)
	SET @own_account = 1

IF  (CHARINDEX('O', UPPER(@template)) <> 0)
	SET @fixed_account = 1

IF (@template = '{OWNE_TEMPLATE}') OR (@template = '{OWN_TEMPLATE}')
	SET @own_account = 1

SET @account_client_no = CASE WHEN @own_account = 1 THEN @client_no ELSE NULL END

IF @type_id BETWEEN 10001 AND 10010 -- ÖÆÒÖÍÅÄËÚÏ×ÉÓ ÀÍÂÀÒÉÛÄÁÉ
BEGIN
	SELECT @bal_acc_alt = BAL_ACC
	FROM dbo.LOAN_CREDIT_LINE_ACCOUNT_TEMPLATES (NOLOCK)
	WHERE COLLATERAL_TYPE = @type_id - 10000
END


IF @bal_acc_alt IS NULL
BEGIN
	SELECT @account_type_descrip = CODE + ':' + DESCRIP 
	FROM dbo.LOAN_ACCOUNT_TYPES
	WHERE TYPE_ID = @type_id
	RAISERROR ('ÛÄÝÃÏÌÀ. ÅÄÒ áÄÒáÃÄÁÀ ÓÀÁÀËÀÍÓÏ ÀÍÂÀÒÉÛÉÓ ÃÀÃÂÄÍÀ(ÓÄÓáÉ #: ''%s''): ''%s''', 16, 1, @agreement_no, @account_type_descrip)
	RETURN 1
END


SET @bal_acc = @bal_acc_alt

EXEC @r = dbo.LOAN_SP_GENERATE_ACCOUNT
	@account		= @account OUTPUT,  
	@template		= @template,
	@branch_id		= 0,
	@dept_id		= 0,
	@bal_acc		= @bal_acc_alt,  
	@loan_bal_acc	= 0,
	@client_no		= @client_no, 
	@ccy			= @iso,
	@loan_ccy		= @credit_line_iso, 
	@prod_code3		= 0,
	@loan_no		= @credit_line_no

IF (@simulate = 1)
BEGIN
	IF @account IS NULL
	BEGIN
		SELECT @account_type_descrip = CODE + ':' + DESCRIP 
		FROM dbo.LOAN_ACCOUNT_TYPES (NOLOCK)
		WHERE [TYPE_ID] = @type_id
        RAISERROR ('ÛÄÝÃÏÌÀ. ÅÄÒ áÄÒáÃÄÁÀ ÀÍÂÀÒÉÛÉÓ ÃÀÃÂÄÍÀ(ÓÄÓáÉ #: ''%s''): ''%s''', 16, 1, @agreement_no, @account_type_descrip)
		RETURN 1
	END

	RETURN
END

DECLARE
	@head_branch bit,
	@head_branch_id int

SELECT @head_branch = CASE WHEN @guarantee = 0 THEN HEAD_BRANCH ELSE GUARANTEE_HEAD_BRANCH END
FROM dbo.LOAN_ACCOUNT_TYPES (NOLOCK)
WHERE [TYPE_ID] = @type_id

SET @head_branch_id = dbo.bank_head_branch_id()

IF @head_branch = 0
	SET @acc_id = dbo.acc_get_acc_id(@branch_id, @account, @iso)
ELSE
	SET @acc_id = dbo.acc_get_acc_id(@head_branch_id, @account, @iso)

IF (@own_account = 0) AND (@fixed_account = 0)
BEGIN
	IF @acc_id IS NULL
	BEGIN
		SELECT @account_type_descrip = convert(varchar(50), @account) 
		RAISERROR ('ÀÍÂÀÒÉÛÉ: ''%s'' ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1, @account_type_descrip)
		RETURN 1
	END
	
	GOTO skip_acc_add
END
ELSE
BEGIN
	IF @acc_id IS NOT NULL
		GOTO skip_acc_add
END 

DECLARE
	@act_pas				tinyint,
	@rec_state				tinyint,
	@descrip				varchar(100),
	@descrip_lat			varchar(100),
	@acc_type				tinyint,
	@acc_subtype			int,
	@date_open				smalldatetime,
	@flags					int


SET @date_open = convert(smalldatetime,floor(convert(real,getdate())))

IF @type_id = 10001
BEGIN
	SET @account				= @account
	SET @iso					= @iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÖÆÒÖÍÅÄËÚÏ×ÉÓ ÓÀáÉÈ ÌÉÝÄÌÖËÉ ÓÀßÀÒÌÏÏ ÌÀÒÀÂÄÁÉ ÃÀ ÌÆÀ ÐÒÏÃÖØÝÉÀ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÖÆÒÖÍÅÄËÚÏ×ÉÓ ÓÀáÉÈ ÌÉÝÄÌÖËÉ ÓÀßÀÒÌÏÏ ÌÀÒÀÂÄÁÉ ÃÀ ÌÆÀ ÐÒÏÃÖØÝÉÀ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 10002
BEGIN
	SET @account				= @account
	SET @iso					= @iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÖÆÒÖÍÅÄËÚÏ×ÉÓ ÓÀáÉÈ ÌÉÝÄÌÖËÉ ÃÄÐÏÆÉÔÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÖÆÒÖÍÅÄËÚÏ×ÉÓ ÓÀáÉÈ ÌÉÝÄÌÖËÉ ÃÄÐÏÆÉÔÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 10003
BEGIN
	SET @account				= @account
	SET @iso					= @iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÖÆÒÖÍÅÄËÚÏ×ÉÓ ÓÀáÉÈ ÌÉÝÄÌÖËÉ ÖÞÒÀÅÉ ØÏÍÄÁÀ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÖÆÒÖÍÅÄËÚÏ×ÉÓ ÓÀáÉÈ ÌÉÝÄÌÖËÉ ÖÞÒÀÅÉ ØÏÍÄÁÀ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 10004
BEGIN
	SET @account				= @account
	SET @iso					= @iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÖÆÒÖÍÅÄËÚÏ×ÉÓ ÓÀáÉÈ ÌÉÝÄÌÖËÉ ÀÙàÖÒÅÉËÏÁÀ ÃÀ ÌÏßÚÏÁÉËÏÁÄÁÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÖÆÒÖÍÅÄËÚÏ×ÉÓ ÓÀáÉÈ ÌÉÝÄÌÖËÉ ÀÙàÖÒÅÉËÏÁÀ ÃÀ ÌÏßÚÏÁÉËÏÁÄÁÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 10005
BEGIN
	SET @account				= @account
	SET @iso					= @iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÖÆÒÖÍÅÄËÚÏ×ÉÓ ÓÀáÉÈ ÌÉÝÄÌÖËÉ ×ÀÓÉÀÍÉ ØÀÙÀËÃÄÁÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÖÆÒÖÍÅÄËÚÏ×ÉÓ ÓÀáÉÈ ÌÉÝÄÌÖËÉ ×ÀÓÉÀÍÉ ØÀÙÀËÃÄÁÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 10006
BEGIN
	SET @account				= @account
	SET @iso					= @iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÖÆÒÖÍÅÄËÚÏ×ÉÓ ÓÀáÉÈ ÌÉÝÄÌÖËÉ ÌÄÓÀÌÄ ÐÉÒÉÓ ÂÀÒÀÍÔÉÀ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÖÆÒÖÍÅÄËÚÏ×ÉÓ ÓÀáÉÈ ÌÉÝÄÌÖËÉ ÌÄÓÀÌÄ ÐÉÒÉÓ ÂÀÒÀÍÔÉÀ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 10007
BEGIN
	SET @account				= @account
	SET @iso					= @iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÖÆÒÖÍÅÄËÚÏ×ÉÓ ÓÀáÉÈ ÌÉÝÄÌÖËÉ ÓÀØÀÒÈÅÄËÏÓ ÌÈÀÅÒÏÁÉÓ ÂÀÒÀÍÔÉÀ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÖÆÒÖÍÅÄËÚÏ×ÉÓ ÓÀáÉÈ ÌÉÝÄÌÖËÉ ÓÀØÀÒÈÅÄËÏÓ ÌÈÀÅÒÏÁÉÓ ÂÀÒÀÍÔÉÀ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 10008
BEGIN
	SET @account				= @account
	SET @iso					= @iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÖÆÒÖÍÅÄËÚÏ×ÉÓ ÓÀáÉÈ ÌÉÝÄÌÖËÉ ÓÀÔÒÀÍÓÐÏÒÔÏ ÓÀÛÖÀËÄÁÄÁÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÖÆÒÖÍÅÄËÚÏ×ÉÓ ÓÀáÉÈ ÌÉÝÄÌÖËÉ ÓÀÔÒÀÍÓÐÏÒÔÏ ÓÀÛÖÀËÄÁÄÁÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 10009
BEGIN
	SET @account				= @account
	SET @iso					= @iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÖÆÒÖÍÅÄËÚÏ×ÉÓ ÓÀáÉÈ ÌÉÝÄÌÖËÉ ÞÅÉÒ×ÀÓÉ ËÉÈÏÍÄÁÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÖÆÒÖÍÅÄËÚÏ×ÉÓ ÓÀáÉÈ ÌÉÝÄÌÖËÉ ÞÅÉÒ×ÀÓÉ ËÉÈÏÍÄÁÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 10010
BEGIN
	SET @account				= @account
	SET @iso					= @iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÖÆÒÖÍÅÄËÚÏ×ÉÓ ÓÀáÉÈ ÌÉÝÄÌÖËÉ ÃÀÍÀÒÜÄÍÉ ÀØÔÉÅÄÁÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÖÆÒÖÍÅÄËÚÏ×ÉÓ ÓÀáÉÈ ÌÉÝÄÌÖËÉ ÃÀÍÀÒÜÄÍÉ ÀØÔÉÅÄÁÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

account_:
IF @account IS NULL
BEGIN
	SELECT @account_type_descrip = CODE + ':' + DESCRIP 
	FROM dbo.LOAN_ACCOUNT_TYPES
	WHERE TYPE_ID = @type_id
	RAISERROR ('ÛÄÝÃÏÌÀ. ÅÄÒ áÄÒáÃÄÁÀ ÀÍÂÀÒÉÛÉÓ ÃÀÃÂÄÍÀ(ÓÄÓáÉ #: ''%s''): ''%s''', 16, 1, @agreement_no, @account_type_descrip)
	RETURN 1
END

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

SELECT @acc_type = CLASS_TYPE, @act_pas = ACT_PAS
FROM dbo.PLANLIST_ALT (NOLOCK)
WHERE BAL_ACC = @bal_acc_alt

IF @head_branch = 1
	SET @dept_no = @head_branch_id


EXEC @r = dbo.ADD_ACCOUNT
	@acc_id			= @acc_id OUTPUT,
	@user_id		= @user_id,
	@dept_no		= @dept_no,
	@account		= @account,
	@iso			= @iso,
	@bal_acc_alt	= @bal_acc_alt,
	@act_pas		= @act_pas,
	@rec_state		= @rec_state,
	@descrip		= @descrip,
	@descrip_lat	= @descrip_lat,
	@acc_type		= @acc_type, 
	@acc_subtype	= @acc_subtype, 
	@client_no		= @account_client_no,
	@date_open		= @date_open,
	@flags			= 0
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

IF @internal_transaction=1 AND @@TRANCOUNT>0
	COMMIT

SET @acc_added = 1
skip_acc_add:

--IF @acc_id IS NOT NULL
--	INSERT INTO dbo.LOAN_CREDIT_LINE_ACCOUNTS(CREDIT_LINE_ID, ACCOUNT_TYPE, ACC_ID)
--	VALUES(@credit_line_id, @type_id, @acc_id)

--IF (@parent_acc_type_id IS NOT NULL) AND (NOT EXISTS(SELECT * FROM dbo.LOAN_CREDIT_LINE_ACCOUNTS (NOLOCK) WHERE CREDIT_LINE_ID=@credit_line_id AND ACCOUNT_TYPE=@parent_acc_type_id))
--  INSERT INTO dbo.LOAN_CREDIT_LINE_ACCOUNTS(CREDIT_LINE_ID, ACCOUNT_TYPE, ACC_ID)
--  VALUES(@credit_line_id, @parent_acc_type_id, @acc_id)

RETURN 0

GO
