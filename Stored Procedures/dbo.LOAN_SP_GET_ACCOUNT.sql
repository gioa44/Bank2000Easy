SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[LOAN_SP_GET_ACCOUNT]
	@acc_id			int OUTPUT,
	@account		TACCOUNT OUTPUT,
	@acc_added		bit OUTPUT,
	@bal_acc		TBAL_ACC OUTPUT,
	@type_id		int,
	@loan_id		int,
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

SELECT @acc_id = ACC_ID FROM dbo.LOAN_ACCOUNTS (NOLOCK) WHERE LOAN_ID = @loan_id AND ACCOUNT_TYPE = @type_id

IF @acc_id IS NOT NULL
BEGIN
	SELECT @account = ACCOUNT, @bal_acc = BAL_ACC_ALT FROM dbo.ACCOUNTS (NOLOCK) WHERE ACC_ID = @acc_id
	RETURN 0
END


DECLARE
	@product_id			int,
	@loan_iso			TISO,
	@branch_id			int,
	@dept_no			int,
	@client_no			int,
	@account_client_no	int,
	@agreement_no		varchar(100),
	@loan_bal_acc		TBAL_ACC,
	@guarantee_internat	bit

DECLARE
	@loan_no int

SELECT
	@dept_no			= DEPT_NO,
	@branch_id			= BRANCH_ID,
	@product_id			= PRODUCT_ID,
	@client_no			= CLIENT_NO,
	@loan_iso			= ISO,
	@agreement_no		= AGREEMENT_NO,
	@loan_bal_acc		= BAL_ACC,
	@guarantee_internat	= INTERNAT_GUARANTEE
FROM dbo.LOANS (NOLOCK)
WHERE LOAN_ID = @loan_id

SELECT @loan_no = COUNT(*)
FROM dbo.LOANS (NOLOCK)
WHERE CLIENT_NO = @client_no AND LOAN_ID < @loan_id

SET @loan_no = ISNULL(@loan_no, 0) + 1

DECLARE
	@client_descrip		varchar(150),
	@client_descrip_lat	varchar(150)

SELECT @client_descrip = DESCRIP, @client_descrip_lat = DESCRIP_LAT
FROM dbo.CLIENTS (NOLOCK)
WHERE CLIENT_NO = @client_no

DECLARE
	@account_type_descrip varchar(150)

/*IF @type_id = 20 -- ÓÄÓáÉÓ ÀÍÂÀÒÉÛÓßÏÒÄÁÉÓ ÀÍÂÀÒÉÛÉ
BEGIN
	SELECT @acc_id = ACC_ID, @account = ACCOUNT
	FROM dbo.ACCOUNTS A (NOLOCK)
		INNER JOIN dbo.LOAN_CLIENT_BAL_ACCS CA (NOLOCK) ON A.BAL_ACC_ALT = CA.ACCOUNT_BAL_ACC
	WHERE A.BRANCH_ID = @branch_id AND CA.BAL_ACC = @loan_bal_acc AND A.CLIENT_NO = @client_no AND A.ISO = @loan_iso AND A.ACC_TYPE = 100 AND (A.REC_STATE NOT IN (2, 128))
	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @acc_id = ACC_ID, @account = ACCOUNT
		FROM dbo.ACCOUNTS A (NOLOCK)
			INNER JOIN dbo.LOAN_CLIENT_BAL_ACCS CA (NOLOCK) ON A.BAL_ACC_ALT = CA.ACCOUNT_BAL_ACC
		WHERE CA.BAL_ACC = @loan_bal_acc AND A.CLIENT_NO = @client_no AND A.ISO = @loan_iso AND A.ACC_TYPE = 100 AND (A.REC_STATE NOT IN (2, 128))
		IF @@ROWCOUNT > 1
		BEGIN
			SELECT @acc_id = NULL, @account = NULL
			SELECT @account_type_descrip = CODE + ':' + DESCRIP 
			FROM dbo.LOAN_ACCOUNT_TYPES (NOLOCK)
			WHERE [TYPE_ID] = @type_id

			RAISERROR ('ÊËÉÄÍÔÓ ÄÊÖÈÅÍÉÓ ÄÒÈÆÄ ÌÄÔÉ ÌÉÌÃÉÍÀÒÄ ÀÍÂÀÒÉÛÉ (ÓÄÓáÉ #: ''%s''): ''%s''', 16, 1, @agreement_no, @account_type_descrip)
			RETURN 1
		END
	END

	IF @acc_id IS NOT NULL
	BEGIN
		INSERT INTO dbo.LOAN_ACCOUNTS(LOAN_ID, ACCOUNT_TYPE, ACC_ID)
		VALUES(@loan_id, @type_id, @acc_id)
		RETURN 0
	END
END*/

IF @type_id = 20 -- ÓÄÓáÉÓ ÀÍÂÀÒÉÛÓßÏÒÄÁÉÓ ÀÍÂÀÒÉÛÉ
BEGIN
	DECLARE
		@client_acc_id int,
		@client_account TACCOUNT,
		@client_acc_iso TISO,
		@client_acc_branch_id int,
		@client_acc_client_no int,
		@client_acc_exists bit
		
	SET @client_acc_exists = 0

	SELECT @client_acc_id = CLIENT_ACCOUNT
	FROM dbo.LOANS (NOLOCK)
	WHERE LOAN_ID = @loan_id


	IF @client_acc_id IS NOT NULL
	BEGIN
		SELECT @client_account = ACCOUNT, @client_acc_iso = ISO, @client_acc_branch_id = BRANCH_ID
		FROM dbo.ACCOUNTS (NOLOCK)
		WHERE ACC_ID = @client_acc_id

		IF @client_acc_iso = @loan_iso
			SET @acc_id = @client_acc_id
		ELSE
		BEGIN
			SELECT @acc_id = ACC_ID, @client_acc_client_no = CLIENT_NO 
			FROM dbo.ACCOUNTS (NOLOCK)
			WHERE ACCOUNT = @client_account AND ISO = @loan_iso AND BRANCH_ID = @client_acc_branch_id

			IF @client_acc_client_no <> @client_no
			BEGIN
				SET @acc_id = NULL
				SET @client_acc_exists = 1
			END
		END
	END

	IF @acc_id IS NOT NULL
	BEGIN
		SET @account = @client_account 
		INSERT INTO dbo.LOAN_ACCOUNTS(LOAN_ID, ACCOUNT_TYPE, ACC_ID)
		VALUES(@loan_id, @type_id, @acc_id)
		RETURN 0
	END
END

DECLARE
	@template varchar(150),
	@parent_acc_type_id	int

IF @type_id < 10001
BEGIN
	IF EXISTS(SELECT * FROM dbo.LOAN_PRODUCT_ACCOUNT_TEMPLATES (NOLOCK) WHERE PRODUCT_ID = @product_id AND ACC_TYPE_ID = @type_id)
	BEGIN
		SELECT @template = TEMPLATE, @parent_acc_type_id = PARENT_ACC_TYPE_ID
		FROM dbo.LOAN_PRODUCT_ACCOUNT_TEMPLATES (NOLOCK)
		WHERE PRODUCT_ID = @product_id AND ACC_TYPE_ID = @type_id

		IF @parent_acc_type_id IS NOT NULL
		BEGIN
			SELECT @template = TEMPLATE
			FROM dbo.LOAN_PRODUCT_ACCOUNT_TEMPLATES (NOLOCK)
			WHERE PRODUCT_ID = @product_id AND ACC_TYPE_ID = @parent_acc_type_id

			SET @acc_id = NULL
			SET @account = NULL
			SET @account_iso = NULL

			SELECT @acc_id = ACC_ID FROM dbo.LOAN_ACCOUNTS (NOLOCK) WHERE LOAN_ID = @loan_id AND ACCOUNT_TYPE = @parent_acc_type_id

			IF @acc_id IS NOT NULL
			BEGIN
				SELECT @account = ACCOUNT, @bal_acc = BAL_ACC_ALT FROM dbo.ACCOUNTS (NOLOCK) WHERE ACC_ID = @acc_id
				GOTO skip_acc_add
			END
		END
	END
	ELSE
	BEGIN
		SELECT @template = TEMPLATE, @parent_acc_type_id = PARENT_ACC_TYPE_ID
		FROM dbo.LOAN_COMMON_ACCOUNT_TEMPLATES (NOLOCK)
		WHERE ACC_TYPE_ID = @type_id

		IF @parent_acc_type_id IS NOT NULL
		BEGIN
			SELECT @template = TEMPLATE
			FROM dbo.LOAN_COMMON_ACCOUNT_TEMPLATES (NOLOCK)
			WHERE ACC_TYPE_ID = @parent_acc_type_id

			SET @acc_id = NULL
			SET @account = NULL
			SET @account_iso = NULL

			SELECT @acc_id = ACC_ID FROM dbo.LOAN_ACCOUNTS (NOLOCK) WHERE LOAN_ID = @loan_id AND ACCOUNT_TYPE = @parent_acc_type_id

			IF @acc_id IS NOT NULL
			BEGIN
				SELECT @account = ACCOUNT, @bal_acc = BAL_ACC_ALT FROM dbo.ACCOUNTS (NOLOCK) WHERE ACC_ID = @acc_id
				GOTO skip_acc_add
			END
		END
	END
END

IF @type_id BETWEEN 10001 AND 10010
BEGIN
	SELECT @template = TEMPLATE
	FROM dbo.LOAN_COLLATERAL_ACCOUNT_TEMPLATES (NOLOCK)
	WHERE COLLATERAL_TYPE = @type_id - 10000	
END

DECLARE
	@r int,
	@bal_acc_alt TBAL_ACC,  
	@prod_code3 int,
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

IF @type_id = 20 -- ÓÄÓáÉÓ ÀÍÂÀÒÉÛÓßÏÒÄÁÉÓ ÀÍÂÀÒÉÛÉ
BEGIN
	SELECT @bal_acc_alt = ACCOUNT_BAL_ACC
	FROM dbo.LOAN_CLIENT_BAL_ACCS (NOLOCK)
	WHERE BAL_ACC = @loan_bal_acc AND OPEN_ACCOUNT = 1
END
ELSE
IF @type_id IN (30, 35)  -- ÓÀÓÄÓáÏ ÀÍÂÀÒÉÛÉ ÀÍ ÓÀÂÀÒÀÍÔÉÏ ßÄÒÉËÉÓ ÀÍÂÀÒÉÛÉ
	SET @bal_acc_alt = @loan_bal_acc
ELSE
IF @type_id BETWEEN 10001 AND 10010 -- ÖÆÒÖÍÅÄËÚÏ×ÉÓ ÀÍÂÀÒÉÛÄÁÉ
BEGIN
	SELECT @bal_acc_alt = BAL_ACC
	FROM dbo.LOAN_COLLATERAL_ACCOUNT_TEMPLATES (NOLOCK)
	WHERE COLLATERAL_TYPE = @type_id - 10000
END
ELSE
BEGIN
	SELECT @bal_acc_alt = ACCOUNT_BAL_ACC
	FROM dbo.LOAN_PRODUCT_BAL_ACCS (NOLOCK)
	WHERE BAL_ACC = @loan_bal_acc AND TYPE_ID = @type_id AND PRODUCT_ID = @product_id

	IF @bal_acc_alt IS NULL
	BEGIN
		SELECT @bal_acc_alt = ACCOUNT_BAL_ACC
		FROM dbo.LOAN_BAL_ACCS (NOLOCK)
		WHERE BAL_ACC = @loan_bal_acc AND TYPE_ID = @type_id
	END
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

SELECT @prod_code3 = CODE3
FROM dbo.LOAN_PRODUCTS (NOLOCK)
WHERE PRODUCT_ID = @product_id

IF @type_id = 20 AND @client_account IS NOT NULL AND @client_acc_exists = 0
  SET @account = @client_account
ELSE
BEGIN
	EXEC @r = dbo.LOAN_SP_GENERATE_ACCOUNT
		@account		= @account OUTPUT,  
		@template		= @template,
		@branch_id		= @branch_id,
		@dept_id		= @dept_no,
		@bal_acc		= @bal_acc,  
		@loan_bal_acc	= @loan_bal_acc,
		@client_no		= @client_no, 
		@ccy			= @iso,
		@loan_ccy		= @loan_iso, 
		@prod_code3		= @prod_code3,
		@loan_no		= @loan_no
END

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

IF @type_id = 10
BEGIN
	SET @account				= @account
	SET @iso					= @loan_iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÀÙÉÀÒÄÁÖËÉ ÓÄÓáÉÓ ÂÀÝÄÌÉÓ ×ÏÒÌÀËÖÒÉ ÅÀËÃÄÁÖËÄÁÀ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÀÙÉÀÒÄÁÖËÉ ÓÄÓáÉÓ ÂÀÝÄÌÉÓ ×ÏÒÌÀËÖÒÉ ÅÀËÃÄÁÖËÄÁÀ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 20
BEGIN
	SET @account				= @account
	SET @iso					= @loan_iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= @client_descrip
	SET @descrip_lat			= @client_descrip_lat

	GOTO account_
END


IF @type_id = 30
BEGIN
	SET @account				= @account
	SET @iso					= @loan_iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÓÄÓáÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' - ' + @client_descrip + ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÓÄÓáÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' - ' + @client_descrip_lat + ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 35
BEGIN
	SET @account				= @account
	SET @iso					= @loan_iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÓÀÂÀÒÀÍÔÉÏ ßÄÒÉËÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' - ' + @client_descrip + ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÓÀÂÀÒÀÍÔÉÏ ßÄÒÉËÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' - ' + @client_descrip_lat + ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 36
BEGIN
	SET @account				= @account
	SET @iso					= @loan_iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÓÀÂÀÒÀÍÔÉÏ ßÄÒÉËÄÁÉ' + CASE WHEN @own_account = 1 THEN ' - ' + @client_descrip + ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÓÀÂÀÒÀÍÔÉÏ ßÄÒÉËÄÁÉ' + CASE WHEN @own_account = 1 THEN ' - ' + @client_descrip_lat + ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 40
BEGIN
	SET @account				= @account
	SET @iso					= @loan_iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÓÄÓáÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' - ' + @client_descrip + ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÓÄÓáÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' - ' + @client_descrip_lat + ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 50
BEGIN
	SET @account				= @account
	SET @iso					= @loan_iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÜÀÌÏßÄÒÉËÉ ÓÄÓáÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' - ' + @client_descrip + ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÜÀÌÏßÄÒÉËÉ ÓÄÓáÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' - ' + @client_descrip + ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 60
BEGIN
	SET @account				= @account
	SET @iso					= @loan_iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÐÒÏÝÄÍÔÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÐÒÏÝÄÍÔÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 70
BEGIN
	SET @account				= @account
	SET @iso					= @loan_iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÜÀÌÏßÄÒÉËÉ ÐÒÏÝÄÍÔÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' - ' + @client_descrip + ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÜÀÌÏßÄÒÉËÉ ÐÒÏÝÄÍÔÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' - ' + @client_descrip + ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 80
BEGIN
	SET @account				= @account
	SET @iso					= @loan_iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÜÀÌÏßÄÒÉËÉ ãÀÒÉÌÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' - ' + @client_descrip + ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÜÀÌÏßÄÒÉËÉ ãÀÒÉÌÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' - ' + @client_descrip + ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 160
BEGIN
	SET @account				= @account
	SET @iso					= @loan_iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÃÒÏÄÁÉÈÉ ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉ ÜÀÌÏßÄÒÉËÉ ÓÄÓáÄÁÉÓÈÅÉÓ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÃÒÏÄÁÉÈÉ ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉ ÜÀÌÏßÄÒÉËÉ ÓÄÓáÄÁÉÓÈÅÉÓ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 170
BEGIN
	SET @account				= @account
	SET @iso					= @iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÃÒÏÄÁÉÈÉ ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉ ÜÀÌÏßÄÒÉËÉ ÓÄÓáÄÁÉÓÈÅÉÓ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÃÒÏÄÁÉÈÉ ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉ ÜÀÌÏßÄÒÉËÉ ÓÄÓáÄÁÉÓÈÅÉÓ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 1000
BEGIN
	SET @account				= @account
	SET @iso					= CASE WHEN @guarantee_internat = 0 THEN @loan_iso ELSE @iso END
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÀÃÌÉÍÉÓÔÒÀÝÉÖËÉ ÂÀÃÀÓÀáÀÃÉÓ ÛÄÌÏÓÀÅÀËÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÀÃÌÉÍÉÓÔÒÀÝÉÖËÉ ÂÀÃÀÓÀáÀÃÉÓ ÛÄÌÏÓÀÅÀËÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 1010
BEGIN
	SET @account				= @account
	SET @iso					= CASE WHEN @guarantee_internat = 0 THEN @loan_iso ELSE @iso END
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÂÀÒÀÍÔÉÄÁÉÃÀÍ ÌÉÓÀÙÄÁÉ ÄÒÈãÄÒÀÃÉ ÊÏÌÉÓÉÀ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÂÀÒÀÍÔÉÄÁÉÃÀÍ ÌÉÓÀÙÄÁÉ ÄÒÈãÄÒÀÃÉ ÊÏÌÉÓÉÀ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 1030
BEGIN
	SET @account				= @account
	SET @iso					= @loan_iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÞÉÒÉÈÀÃ ÈÀÍáÀÆÄ ÃÀÒÉÝáÖËÉ ÐÒÏÝÄÍÔÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÞÉÒÉÈÀÃ ÈÀÍáÀÆÄ ÃÀÒÉÝáÖËÉ ÐÒÏÝÄÍÔÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 1130
BEGIN
	SET @account				= @account
	SET @iso					= @loan_iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÞÉÒÉÈÀÃ ÈÀÍáÀÆÄ ÃÀÒÉÝáÖËÉ ÐÒÏÝÄÍÔÉÓ ÛÄÌÏÓÀÅËÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÞÉÒÉÈÀÃ ÈÀÍáÀÆÄ ÃÀÒÉÝáÖËÉ ÐÒÏÝÄÍÔÉÓ ÛÄÌÏÓÀÅËÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 1160
BEGIN
	SET @account				= @account
	SET @iso					= @loan_iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÅÀÃÀÂÀÃÀÝÉËÄÁÖË ÐÒÏÝÄÍÔÉÓ ÛÄÌÏÓÀÅËÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÅÀÃÀÂÀÃÀÝÉËÄÁÖË ÐÒÏÝÄÍÔÉÓ ÛÄÌÏÓÀÅËÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 1170
BEGIN
	SET @account				= @account
	SET @iso					= @loan_iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÜÀÌÏßÄÒÉËÉ ÐÒÏÝÄÍÔÉÓ ÛÄÌÏÓÀÅËÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÜÀÌÏßÄÒÉËÉ ÐÒÏÝÄÍÔÉÓ ÛÄÌÏÓÀÅËÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 2000
BEGIN
	SET @account				= @account
	SET @iso					= @loan_iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÃÀÒÉÝáÖËÉ ãÀÒÉÌÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÃÀÒÉÝáÖËÉ ãÀÒÉÌÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 2060
BEGIN
	SET @account				= @account
	SET @iso					= @loan_iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= '30 ÃÙÄÆÄ ÌÄÔÉ ÅÀÃÉÈ ÌÉÖÙÄÁÄËÉ ÐÒÏÝÄÍÔÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= '30 ÃÙÄÆÄ ÌÄÔÉ ÅÀÃÉÈ ÌÉÖÙÄÁÄËÉ ÐÒÏÝÄÍÔÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 2100
BEGIN
	SET @account				= @account
	SET @iso					= @loan_iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÃÀÒÉÝáÖËÉ ãÀÒÉÌÉÓ ÛÄÌÏÓÀÅËÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÃÀÒÉÝáÖËÉ ãÀÒÉÌÉÓ ÛÄÌÏÓÀÅËÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 3000
BEGIN
	SET @account				= @account
	SET @iso					= @loan_iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ßÉÍÓßÒÄÁÉÓ ÓÀÊÏÌÉÓÏÓ ÛÄÌÏÓÀÅËÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ßÉÍÓßÒÄÁÉÓ ÓÀÊÏÌÉÓÏÓ ÛÄÌÏÓÀÅËÉÓ ÀÍÂÀÒÉÛÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 3100
BEGIN
	SET @account				= @account
	SET @iso					= @loan_iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÌÏÌÓÀáÖÒÄÁÉÓ ÂÀÃÀÓÀáÀÃÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÌÏÌÓÀáÖÒÄÁÉÓ ÂÀÃÀÓÀáÀÃÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 4000
BEGIN
	SET @account				= @account
	SET @iso					= @loan_iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÓÀÊÖÒÓÏ ÓáÅÀÏÁÉÈ ÌÉÙÄÁÖËÉ ÛÄÌÏÓÀÅËÄÁÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÓÀÊÖÒÓÏ ÓáÅÀÏÁÉÈ ÌÉÙÄÁÖËÉ ÛÄÌÏÓÀÅËÄÁÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 5000
BEGIN
	SET @account				= @account
	SET @iso					= @loan_iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÌÉÙÄÁÖËÉ ÓÀÃÀÆÙÅÄÅÏ ÐÒÄÌÉÀ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÌÉÙÄÁÖËÉ ÓÀÃÀÆÙÅÄÅÏ ÐÒÄÌÉÀ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 8000
BEGIN
	SET @account				= @account
	SET @iso					= @iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÓÄÓáÉÓ ÛÄÓÀÞËÏ ÃÀÍÀÊÀÒÂÄÁÉÓ ÒÄÆÄÒÅÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÓÄÓáÉÓ ÛÄÓÀÞËÏ ÃÀÍÀÊÀÒÂÄÁÉÓ ÒÄÆÄÒÅÉ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 8010
BEGIN
	SET @account				= @account
	SET @iso					= @iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÓÄÓáÉÓ ÛÄÓÀÞËÏ ÃÀÍÀÊÀÒÂÄÁÉÓ ÒÄÆÄÒÅÉ (I ÊÀÔÄÂÏÒÉÀ)' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÓÄÓáÉÓ ÛÄÓÀÞËÏ ÃÀÍÀÊÀÒÂÄÁÉÓ ÒÄÆÄÒÅÉ (I ÊÀÔÄÂÏÒÉÀ)' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 8020
BEGIN
	SET @account				= @account
	SET @iso					= @iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÓÄÓáÉÓ ÛÄÓÀÞËÏ ÃÀÍÀÊÀÒÂÄÁÉÓ ÒÄÆÄÒÅÉ (II ÊÀÔÄÂÏÒÉÀ)' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÓÄÓáÉÓ ÛÄÓÀÞËÏ ÃÀÍÀÊÀÒÂÄÁÉÓ ÒÄÆÄÒÅÉ (II ÊÀÔÄÂÏÒÉÀ)' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 8030
BEGIN
	SET @account				= @account
	SET @iso					= @iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÓÄÓáÉÓ ÛÄÓÀÞËÏ ÃÀÍÀÊÀÒÂÄÁÉÓ ÒÄÆÄÒÅÉ (III ÊÀÔÄÂÏÒÉÀ)' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÓÄÓáÉÓ ÛÄÓÀÞËÏ ÃÀÍÀÊÀÒÂÄÁÉÓ ÒÄÆÄÒÅÉ (III ÊÀÔÄÂÏÒÉÀ)' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 8040
BEGIN
	SET @account				= @account
	SET @iso					= @iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÓÄÓáÉÓ ÛÄÓÀÞËÏ ÃÀÍÀÊÀÒÂÄÁÉÓ ÒÄÆÄÒÅÉ (IV ÊÀÔÄÂÏÒÉÀ)' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÓÄÓáÉÓ ÛÄÓÀÞËÏ ÃÀÍÀÊÀÒÂÄÁÉÓ ÒÄÆÄÒÅÉ (IV ÊÀÔÄÂÏÒÉÀ)' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 8050
BEGIN
	SET @account				= @account
	SET @iso					= @iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÓÄÓáÉÓ ÛÄÓÀÞËÏ ÃÀÍÀÊÀÒÂÄÁÉÓ ÒÄÆÄÒÅÉ (IV ÊÀÔÄÂÏÒÉÀ)' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÓÄÓáÉÓ ÛÄÓÀÞËÏ ÃÀÍÀÊÀÒÂÄÁÉÓ ÒÄÆÄÒÅÉ (IV ÊÀÔÄÂÏÒÉÀ)' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 9000
BEGIN
	SET @account				= @account
	SET @iso					= @iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÆÀÒÀËÉ ÓÄÓáÄÁÉÓ ÛÄÓÀÞËÏ ÃÀÍÀÊÀÒÂÄÁÉÓ ÌÉáÄÃÅÉÈ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÆÀÒÀËÉ ÓÄÓáÄÁÉÓ ÛÄÓÀÞËÏ ÃÀÍÀÊÀÒÂÄÁÉÓ ÌÉáÄÃÅÉÈ' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 9010
BEGIN
	SET @account				= @account
	SET @iso					= @iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÆÀÒÀËÉ ÓÄÓáÄÁÉÓ ÛÄÓÀÞËÏ ÃÀÍÀÊÀÒÂÄÁÉÓ ÌÉáÄÃÅÉÈ (I ÊÀÔÄÂÏÒÉÀ)' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÆÀÒÀËÉ ÓÄÓáÄÁÉÓ ÛÄÓÀÞËÏ ÃÀÍÀÊÀÒÂÄÁÉÓ ÌÉáÄÃÅÉÈ (I ÊÀÔÄÂÏÒÉÀ)' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 9020
BEGIN
	SET @account				= @account
	SET @iso					= @iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÆÀÒÀËÉ ÓÄÓáÄÁÉÓ ÛÄÓÀÞËÏ ÃÀÍÀÊÀÒÂÄÁÉÓ ÌÉáÄÃÅÉÈ (II ÊÀÔÄÂÏÒÉÀ)' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÆÀÒÀËÉ ÓÄÓáÄÁÉÓ ÛÄÓÀÞËÏ ÃÀÍÀÊÀÒÂÄÁÉÓ ÌÉáÄÃÅÉÈ (II ÊÀÔÄÂÏÒÉÀ)' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 9030
BEGIN
	SET @account				= @account
	SET @iso					= @iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÆÀÒÀËÉ ÓÄÓáÄÁÉÓ ÛÄÓÀÞËÏ ÃÀÍÀÊÀÒÂÄÁÉÓ ÌÉáÄÃÅÉÈ (III ÊÀÔÄÂÏÒÉÀ)' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÆÀÒÀËÉ ÓÄÓáÄÁÉÓ ÛÄÓÀÞËÏ ÃÀÍÀÊÀÒÂÄÁÉÓ ÌÉáÄÃÅÉÈ (III ÊÀÔÄÂÏÒÉÀ)' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 9040
BEGIN
	SET @account				= @account
	SET @iso					= @iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÆÀÒÀËÉ ÓÄÓáÄÁÉÓ ÛÄÓÀÞËÏ ÃÀÍÀÊÀÒÂÄÁÉÓ ÌÉáÄÃÅÉÈ (IV ÊÀÔÄÂÏÒÉÀ)' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÆÀÒÀËÉ ÓÄÓáÄÁÉÓ ÛÄÓÀÞËÏ ÃÀÍÀÊÀÒÂÄÁÉÓ ÌÉáÄÃÅÉÈ (IV ÊÀÔÄÂÏÒÉÀ)' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

IF @type_id = 9050
BEGIN
	SET @account				= @account
	SET @iso					= @iso
	SET @bal_acc_alt			= @bal_acc
	SET @rec_state				= 1
	SET @descrip				= 'ÆÀÒÀËÉ ÓÄÓáÄÁÉÓ ÛÄÓÀÞËÏ ÃÀÍÀÊÀÒÂÄÁÉÓ ÌÉáÄÃÅÉÈ (V ÊÀÔÄÂÏÒÉÀ)' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END
	SET @descrip_lat			= 'ÆÀÒÀËÉ ÓÄÓáÄÁÉÓ ÛÄÓÀÞËÏ ÃÀÍÀÊÀÒÂÄÁÉÓ ÌÉáÄÃÅÉÈ (V ÊÀÔÄÂÏÒÉÀ)' + CASE WHEN @own_account = 1 THEN ' (áÄËÛ. ' + @agreement_no + ')' ELSE '' END

	GOTO account_
END

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

IF NOT @type_id BETWEEN 10001 AND 10010
BEGIN
	IF @acc_id IS NOT NULL 
		INSERT INTO dbo.LOAN_ACCOUNTS(LOAN_ID, ACCOUNT_TYPE, ACC_ID)
		VALUES(@loan_id, @type_id, @acc_id)

	IF (@parent_acc_type_id IS NOT NULL) AND (NOT EXISTS(SELECT * FROM dbo.LOAN_ACCOUNTS (NOLOCK) WHERE LOAN_ID=@loan_id AND ACCOUNT_TYPE=@parent_acc_type_id))
	  INSERT INTO dbo.LOAN_ACCOUNTS(LOAN_ID, ACCOUNT_TYPE, ACC_ID)
	  VALUES(@loan_id, @parent_acc_type_id, @acc_id)
END

RETURN 0
GO
