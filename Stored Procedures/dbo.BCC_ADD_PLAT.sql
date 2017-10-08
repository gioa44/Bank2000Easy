SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[BCC_ADD_PLAT]
	@rec_id int OUTPUT,					-- რა შიდა ნომრით დაემატა საბუთი
	@date_changed bit OUTPUT,			-- შეეცვალა თუ არა საბუთს თარიღი
	@bc_login_id int,					-- ბანკ-კლიენტის მომხმარებლის ID

	@doc_date smalldatetime,			-- საბუთის თარიღი
	@iso TISO = 'GEL',					-- ვალუტის კოდი
	@amount money,						-- თანხა
	@descrip varchar(150) = NULL,		-- დანიშნულება
	@op_code TOPCODE = '',				-- ოპერაციის კოდი
	@doc_num int = NULL,				-- საბუთის ნომერი ან კოდი

	@sender_acc TACCOUNT,

	@receiver_bank_code TINTBANKCODE,
	@receiver_bank_name varchar(100) = NULL,
	@receiver_acc TINTACCOUNT,
	@receiver_acc_name varchar(100),
	@receiver_tax_code varchar(11) = NULL,

	@intermed_bank_code TINTBANKCODE = NULL,
	@intermed_bank_name varchar(100) = NULL,

	@ref_num varchar(32) = NULL,
	@saxazkod varchar(9) = NULL,
	@tax_payer_tax_code varchar(11) = NULL, -- გადასახადის გადამხდელის საგადასახადო კოდი
	@tax_payer_name varchar(100) = NULL, -- გადასახადის გადამხდელის დასახელება


	@extra_info varchar(250) = NULL,
	@extra_param TACCOUNT = NULL,	-- დამატებითი პარამეტრი

	@is_val bit = 0,
	@level1 bit = 0,
	@channel_id int = 200,	-- არხი, რომლითაც ემატება ეს საბუთი
							-- 200 - ბანკი-კლიენტი
							-- 900 - ინტერნეტ ბანკინგი
	@foreign_id int,			-- გარე ნომერი
							-- ბანკ-კლიენტის შემთხვევაში საბუთის შიდა ნომერი იმ ბაზაში, საიდანაც ემატება.
							-- ინტერნეტ ბანკინგის შემთხვევაში, ???

	@lat bit = 0			-- გამოიტანოს თუ არა შეცდომები ინგლისურად
AS
 
SET NOCOUNT ON

IF @iso = 'GEL' 
  SET @is_val = 0

DECLARE
	@check_receiver_name int,
	@today smalldatetime,
	@bc_client_id int,
	@bc_client_flags int,
	@bc_login_flags int,
	@bc_login_flags2 int,
	@client_type tinyint,
	@owner int,
	@doc_date_in_doc smalldatetime,
	@rec_state tinyint,
	@client_branch_id int

SET @today = convert(smalldatetime,floor(convert(real,getdate())))
 
SET @doc_date_in_doc = @doc_date
SET @rec_state = 0

SELECT @bc_client_id = BC_CLIENT_ID, @bc_login_flags = FLAGS, @bc_login_flags2 = FLAGS2
FROM dbo.BC_LOGINS (NOLOCK)
WHERE BC_LOGIN_ID = @bc_login_id
IF @@ROWCOUNT = 0
BEGIN
  RAISERROR ('<ERR>INTERNAL ERROR #0001. PLEASE CONTACT ALTA Software Ltd.</ERR>',16,1)
  RETURN (1001)
END
 
SELECT @owner = BNK_CLI_OPER_ID, @bc_client_flags = FLAGS, @client_type = CLIENT_TYPE, @client_branch_id = BRANCH_ID
FROM dbo.BC_CLIENTS
WHERE BC_CLIENT_ID = @bc_client_id
IF @@ROWCOUNT = 0
BEGIN
  RAISERROR ('<ERR>INTERNAL ERROR #0002. PLEASE CONTACT ALTA Software Ltd.</ERR>',16,1)
  RETURN (1002)
END
 
/* Check ClientType */
IF @client_type <> 0
BEGIN
  IF @lat = 0 
       RAISERROR ('<ERR>ÈØÅÄÍ ÀÒ ÂÀØÅÈ ÀÌÉÓ Ö×ËÄÁÀ</ERR>',16,1)
  ELSE RAISERROR ('<ERR>You don''t have rignts to do this"</ERR>',16,1)
  RETURN (1009)
END

DECLARE @disable_flag int
SET @disable_flag = CASE WHEN @channel_id = 900 THEN 2 ELSE 1 END

/* Check login rights */
IF @bc_login_flags & @disable_flag = 0  /* not internet or BC enabled */ OR @bc_login_flags2 = 0
BEGIN
  IF @lat = 0 
       RAISERROR ('<ERR>ÈØÅÄÍ ÀÒ ÂÀØÅÈ ÀÌÉÓ Ö×ËÄÁÀ</ERR>',16,1)
  ELSE RAISERROR ('<ERR>You don''t have rignts to do this"</ERR>',16,1)
  RETURN (1000)
END

/* Check login rights */
IF (@bc_client_flags & @disable_flag = 0)  /* not internet or BC enabled */
--  OR (@bc_client_flags & 2048 = 0)  /* not can_add_plat */ 
BEGIN
  IF @lat = 0 
       RAISERROR ('<ERR>ÈØÅÄÍ ÀÒ ÂÀØÅÈ ÀÌÉÓ Ö×ËÄÁÀ</ERR>',16,1)
  ELSE RAISERROR ('<ERR>You don''t have rignts to do this"</ERR>',16,1)
  RETURN (1000)
END

IF @amount <= $0.00
BEGIN
  IF @lat = 0 
       RAISERROR('<ERR>ÈÀÍáÀ ÖÍÃÀ ÉÚÏÓ ÍÖËÆÄ ÌÄÔÉ</ERR>',16,1)
  ELSE RAISERROR('<ERR>Amount must be more than zero</ERR>',16,1);
  RETURN (2)
END

EXEC dbo.GET_SETTING_INT 'BCC_CHECK_RECV_NAME', @check_receiver_name OUTPUT

SET @date_changed = 0
IF @doc_date < @today
BEGIN
  SET @doc_date = @today
  SET @date_changed = 1
END

IF @channel_id <> 900 /* Not Internet Banking */
	EXEC dbo.BCC_GET_DOC_DATE @bc_login_id, @doc_date OUTPUT, @date_changed OUTPUT

DECLARE 
	@r int,
	@for_what varchar(10),
	@sender_acc_id int,
	@credit TACCOUNT,
	@credit_id int,
	@doc_type tinyint,
	@sender_branch_id int
	
SELECT @sender_acc_id = LA.ACC_ID, @sender_branch_id = @client_branch_id
FROM dbo.BC_LOGIN_ACC_VIEW LA (NOLOCK)
	INNER JOIN dbo.ACCOUNTS A (NOLOCK) ON A.ACC_ID = LA.ACC_ID
WHERE LA.BC_LOGIN_ID = @bc_login_id AND A.BRANCH_ID = @client_branch_id AND A.ACCOUNT = @sender_acc AND A.ISO = @iso

IF @sender_acc_id IS NULL
	SELECT TOP 1 @sender_acc_id = LA.ACC_ID, @sender_branch_id = A.BRANCH_ID
	FROM dbo.BC_LOGIN_ACC_VIEW LA (NOLOCK)
		INNER JOIN dbo.ACCOUNTS A (NOLOCK) ON A.ACC_ID = LA.ACC_ID
	WHERE LA.BC_LOGIN_ID = @bc_login_id AND A.ACCOUNT = @sender_acc AND A.ISO = @iso


-- Check receiver acc

DECLARE
	@_receiver_acc_name varchar(100),
	@_receiver_tax_code varchar(11)
 
SET @credit_id = NULL

DECLARE @percent int

IF @is_val = 0 AND dbo.bank_is_geo_bank_in_our_db(@receiver_bank_code) <> 0
BEGIN
	SET @doc_type = 100

	SELECT TOP 1 @credit_id = A.ACC_ID
	FROM dbo.ACCOUNTS A
		INNER JOIN dbo.DEPTS D ON D.BRANCH_ID = A.BRANCH_ID
	WHERE D.CODE9 = @receiver_bank_code AND D.IS_DEPT = 0 AND A.ACCOUNT = @receiver_acc AND A.ISO = @iso
	ORDER BY D.DEPT_NO

	EXEC @r = dbo.BCC_CHECK_RECV_ACC @credit_id, @receiver_acc, @iso, @_receiver_acc_name OUTPUT, @_receiver_tax_code OUTPUT, @lat, 0
	IF @@ERROR <> 0 OR @r <> 0 RETURN(7)
	
	IF @check_receiver_name <> 0
		SET @percent = dbo.clr_string_compare (@receiver_acc_name, @_receiver_acc_name)
	ELSE
		SET @percent = 100
	IF @percent < 100
	BEGIN
		IF @lat = 0 
		   RAISERROR ('<ERR>ÌÉÌÙÄÁÉÓ ÃÀÓÀáÄËÄÁÀ ÀÒ ÄÌÈáÅÄÅÀ ÁÀÍÊÛÉ ÀÒÓÄÁÖË ÃÀÓÀáÄËÄÁÀÓ: %s</ERR>',16,1,@_receiver_acc_name)
		ELSE RAISERROR ('<ERR>Receiver''s name doesn''t match with the one in the bank: %s</ERR>',16,1,@_receiver_acc_name)
		RETURN 1
	END
END
ELSE
IF @is_val = 1 AND dbo.bank_is_int_bank_in_our_db(@receiver_bank_code) <> 0
BEGIN
	SET @doc_type = 110

	IF SUBSTRING(@receiver_bank_code, 1, 8) = 'REPLGE22'
	BEGIN
		SELECT @credit_id = A.ACC_ID
		FROM dbo.ACCOUNTS A
			INNER JOIN dbo.DEPTS D ON D.BRANCH_ID = A.BRANCH_ID
		WHERE D.IS_DEPT = 0 AND A.ACCOUNT = @receiver_acc AND A.ISO = @iso
		ORDER BY D.DEPT_NO DESC

		IF @@ROWCOUNT > 1
		BEGIN
			IF @lat = 0 
				RAISERROR('<ERR>ÀÍÂÀÒÉÛÉ ÀÓÄÈÉ ÍÏÌÒÉÈ ÀÒÉÓ ÒÀÌÏÃÄÍÉÌÄ. ÂÀÔÀÒÄÁÀ ÛÄÖÞËÄÁÄËÉÀ. ÂÈáÏÅÈ ÌÉÌÀÒÈÏÈ ÁÀÍÊ-ÊËÉÄÍÔÉÓ ÀÃÌÉÍÉÓÔÒÀÔÏÒÓ</ERR>',16,1)
			ELSE RAISERROR('<ERR>There''s more than 1 account with the same account number. Cannot complete transaction. Please contact bank-client administrator</ERR>',16,1);

			RETURN 1
		END
	END
	ELSE
	BEGIN
		SELECT TOP 1 @credit_id = A.ACC_ID
		FROM dbo.ACCOUNTS A
			INNER JOIN dbo.DEPTS D ON D.BRANCH_ID = A.BRANCH_ID
		WHERE D.BIC = @receiver_bank_code AND D.IS_DEPT = 0 AND A.ACCOUNT = @receiver_acc AND A.ISO = @iso
		ORDER BY D.DEPT_NO
	END

	EXEC @r = dbo.BCC_CHECK_RECV_ACC @credit_id, @receiver_acc, @iso, @_receiver_acc_name OUTPUT, @_receiver_tax_code OUTPUT, @lat, 1
	IF @@ERROR <> 0 OR @r <> 0 RETURN(7)

	IF @check_receiver_name <> 0
		SET @percent = dbo.clr_string_compare (@receiver_acc_name, @_receiver_acc_name)
	ELSE
		SET @percent = 100
	IF @percent < 100
	BEGIN
		IF @lat = 0 
		   RAISERROR ('<ERR>ÌÉÌÙÄÁÉÓ ÃÀÓÀáÄËÄÁÀ ÀÒ ÄÌÈáÅÄÅÀ ÁÀÍÊÛÉ ÀÒÓÄÁÖË ÃÀÓÀáÄËÄÁÀÓ: %s</ERR>',16,1,@_receiver_acc_name)
		ELSE RAISERROR ('<ERR>Receiver''s name doesn''t match with the one in the bank: %s</ERR>',16,1,@_receiver_acc_name)
		RETURN 1
	END
END
ELSE
IF @is_val = 0 AND dbo.bank_is_geo_bank_in_our_db(@receiver_bank_code) = 0
BEGIN
	SET @doc_type = 102

    EXEC dbo.GET_SETTING_ACC 'CORR_ACC_NA', @credit OUTPUT
	SET @credit_id = dbo.acc_get_acc_id (dbo.bank_head_branch_id(), @credit, @iso)
END
ELSE
IF @is_val = 1 AND dbo.bank_is_int_bank_in_our_db(@receiver_bank_code) = 0
BEGIN
	SET @doc_type = 112

	EXEC dbo.GET_SETTING_ACC 'CORR_ACC_VA', @credit OUTPUT
	SET @credit_id = dbo.acc_get_acc_id (dbo.bank_head_branch_id(), @credit, @iso)
END

-- Check sender acc
DECLARE @internal_transfer bit
SET @internal_transfer = 0

IF @op_code = 'WBPLI'
	SET @for_what = 'debit'
ELSE
IF @op_code = '*POL*'
	SET @for_what = ''
ELSE 
BEGIN
	SET @for_what = 'plat'

	IF EXISTS (SELECT * FROM dbo.BC_LOGIN_ACC_VIEW LA (NOLOCK) WHERE LA.BC_LOGIN_ID = @bc_login_id AND LA.ACC_ID = @credit_id)
	BEGIN
		SET @for_what = 'debit'
		SET @internal_transfer = 1
	END
END

EXEC @r = dbo.BCC_CHECK_ACC @bc_client_id, @bc_login_id, @sender_acc_id, @lat, @for_what, @disable_flag
IF @@ERROR <> 0 OR @r <> 0 RETURN(1)

IF @internal_transfer = 1 AND @doc_type in (100, 110)
BEGIN
	EXEC @r = dbo.BCC_CHECK_ACC @bc_client_id, @bc_login_id, @credit_id, @lat, 'credit', @disable_flag
	IF @@ERROR <> 0 OR @r <> 0 RETURN(1)
END

-----

IF @level1 <> 0 AND @date_changed = 0 
BEGIN
	SET @rec_state = 10	
END

IF @iso = 'GEL' AND dbo.is_trasury_transfer (@receiver_bank_code, @receiver_acc) <> 0
BEGIN
  SET @extra_info = LTRIM(ISNULL(@extra_info,'') + ' ') + @descrip

  EXEC @r = dbo.BCC_CHECK_SAXAZCODE @saxazkod, @receiver_acc, @lat, @descrip OUTPUT, @receiver_acc_name OUTPUT
  IF @@ERROR <> 0 OR @r <> 0 RETURN(1)
END

 
EXEC @r = dbo.BCC_CHECK_ACC_LIMITS @bc_login_id, @sender_acc_id, @amount, @doc_date, @lat
IF @@ERROR <> 0 OR @r <> 0 RETURN(4)
 
EXEC @r = dbo.BCC_CHECK_LOGIN_LIMITS @bc_login_id, @amount, @doc_date, @lat
IF @@ERROR <> 0 OR @r <> 0 RETURN(5)
 
EXEC @r = dbo.BCC_CHECK_BNK_LIMITS @bc_client_id, @amount, @doc_date, @lat
IF @@ERROR <> 0 OR @r <> 0 RETURN(6)
 

IF EXISTS( SELECT * FROM dbo.OPS_0000 (NOLOCK)
           WHERE BNK_CLI_ID = @bc_login_id AND CHANNEL_ID = @channel_id AND FOREIGN_ID = @foreign_id AND 
			ISO = @iso AND AMOUNT = @amount)
BEGIN
  IF @lat = 0 
       RAISERROR ('<ERR>ÄÓ ÓÀÁÖÈÉ ÀËÁÀÈ ÖÊÅÄ ÃÀÌÀÔÄÁÖËÉÀ ÁÀÍÊÉÓ ÓÀÁÖÈÄÁÉÓ ÓÉÀÛÉ. ÂÈáÏÅÈ ÂÀÃÀÀÌÏßÌÏÈ.</ERR>',16,1)
  ELSE RAISERROR ('<ERR>This document is likely to be in bank''s directory of documents. Please check again.</ERR>',16,1)
  RETURN (1)
END

IF @is_val = 0
BEGIN
	IF NOT EXISTS(SELECT * FROM dbo.ops_accounts_plat_inner_debit where ACC_ID = @sender_acc_id)
	BEGIN
	  IF @lat = 0 
		   RAISERROR ('<ERR>ÀÌ ÀÍÂÀÒÉÛÉÃÀÍ ÀÒ ÂÀØÅÈ ÂÀÃÀÒÉÝáÅÉÓ Ö×ËÄÁÀ.</ERR>',16,1)
	  ELSE RAISERROR ('<ERR>You cannot transfer money from this account.</ERR>',16,1)
	  RETURN (1)
	END
END
ELSE
BEGIN
	IF NOT EXISTS(SELECT * FROM dbo.ops_accounts_valplat_inner_debit where ACC_ID = @sender_acc_id)
	BEGIN
	  IF @lat = 0 
		   RAISERROR ('<ERR>ÀÌ ÀÍÂÀÒÉÛÉÃÀÍ ÀÒ ÂÀØÅÈ ÂÀÃÀÒÉÝáÅÉÓ Ö×ËÄÁÀ.</ERR>',16,1)
	  ELSE RAISERROR ('<ERR>You cannot transfer money from this account.</ERR>',16,1)
	  RETURN (1)
	END
END

DECLARE
	@client_no int,
	@sender_bank_name varchar(100),
	@sender_acc_name varchar(100),
	@sender_tax_code varchar(11),
	@our_bank_code TINTBANKCODE

SELECT @our_bank_code = CASE WHEN @is_val = 0 THEN CONVERT(varchar(30),CODE9) ELSE BIC END
FROM dbo.DEPTS (NOLOCK)
WHERE DEPT_NO = @sender_branch_id
	
SELECT @client_no = CLIENT_NO, @sender_acc_name = CASE WHEN @is_val = 0 THEN DESCRIP ELSE DESCRIP_LAT END
FROM dbo.ACCOUNTS (NOLOCK)
WHERE ACC_ID = @sender_acc_id

SELECT @sender_tax_code = CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END
FROM dbo.CLIENTS C (NOLOCK)
WHERE C.CLIENT_NO = @client_no
	
DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

IF @is_val = 0
BEGIN
	SELECT @sender_bank_name = DESCRIP 
	FROM dbo.BANKS(NOLOCK)
	WHERE CODE9 = @our_bank_code

	SELECT @receiver_bank_name = DESCRIP FROM dbo.BANKS(NOLOCK)
	WHERE CODE9 = @receiver_bank_code

	EXEC @r = dbo.ADD_DOC4
		@rec_id OUTPUT,
		@user_id = 8,
		@owner = @owner,
		@doc_date = @doc_date,
		@doc_date_in_doc = @doc_date_in_doc,
		@iso = @iso,
		@amount = @amount,
		@doc_num = @doc_num,
		@op_code = @op_code,
		@rec_state = @rec_state,
		@bnk_cli_id = @bc_login_id,
		@descrip = @descrip,
		@dept_no = @client_branch_id,

		@doc_type = @doc_type,
		@debit_id = @sender_acc_id,
		@credit_id = @credit_id,

		@sender_bank_code = @our_bank_code,
		@sender_bank_name = @sender_bank_name,
		@sender_acc = @sender_acc,
		@sender_acc_name = @sender_acc_name,
		@sender_tax_code = @sender_tax_code,

		@receiver_bank_code = @receiver_bank_code,
		@receiver_bank_name = @receiver_bank_name,
		@receiver_acc = @receiver_acc,
		@receiver_acc_name = @receiver_acc_name,
		@receiver_tax_code = @receiver_tax_code,

		@saxazkod = @saxazkod,
		@tax_payer_tax_code = @tax_payer_tax_code,
		@tax_payer_name = @tax_payer_name,

		@rec_date = @doc_date,
		@ref_num = @ref_num,
		@extra_info = @extra_info,
		@account_extra = @extra_param,

		@channel_id = @channel_id,
		@foreign_id = @foreign_id,

		@lat = @lat
END

ELSE
BEGIN
	SELECT @sender_bank_name = DESCRIP_LAT
	FROM dbo.DEPTS (NOLOCK)
	WHERE DEPT_NO = @sender_branch_id

	DECLARE @address_lat varchar(100)

	SET @address_lat = dbo.cli_get_cli_attribute (@client_no, '$ADDRESS_LAT')

	EXEC @r = dbo.ADD_DOC4
		@rec_id OUTPUT,
		@user_id = 8,
		@owner = @owner,
		@doc_date = @doc_date,
		@doc_date_in_doc = @doc_date_in_doc,
		@iso = @iso,
		@amount = @amount,
		@doc_num = @doc_num,
		@op_code = @op_code,
		@rec_state = @rec_state,
		@bnk_cli_id = @bc_login_id,
		@descrip = @descrip,
		@dept_no = @client_branch_id,

		@doc_type = @doc_type,
		@debit_id = @sender_acc_id,
		@credit_id = @credit_id,

		@sender_bank_code = @our_bank_code,
		@sender_bank_name = @sender_bank_name,
		@sender_acc = @sender_acc,
		@sender_acc_name = @sender_acc_name,
		@sender_tax_code = @sender_tax_code,
	
		@receiver_bank_code = @receiver_bank_code,
		@receiver_bank_name = @receiver_bank_name,
		@receiver_acc = @receiver_acc,
		@receiver_acc_name = @receiver_acc_name,
		@receiver_tax_code = @receiver_tax_code,

		@intermed_bank_code = @intermed_bank_code,
		@intermed_bank_name = @intermed_bank_name,

		@ref_num = @ref_num,
		@extra_info = @extra_info,
		@account_extra = @extra_param,

		@sender_address_lat = @address_lat,

		@channel_id = @channel_id,
		@foreign_id = @foreign_id,

		@lat = @lat
END

IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 31 END	
 
IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN
RETURN (0)
GO
