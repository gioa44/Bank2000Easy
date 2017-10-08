SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE  [dbo].[BCC_ADD_CONV]
  @rec_id int OUTPUT,				-- რა შიდა ნომრით დაემატა საბუთი
  @date_changed bit OUTPUT,			-- შეეცვალა თუ არა საბუთს თარიღი
  @rate_changed bit OUTPUT,			-- შეეცვალა თუ არა საბუთს კურსი
  @bc_login_id int,					-- ბანკ-კლიენტის მომხმარებლის ID
    
  @iso_d TISO,				-- ვალუტის კოდი 1
  @iso_c TISO,				-- ვალუტის კოდი 2

  @fix_a bit,

  @amount_d money,			-- თანხა 1
  @amount_c money,			-- თანხა 2

  @debit TACCOUNT,			-- დებეტის ანგარიში
  @credit TACCOUNT,			-- კრედიტის ანგარიში

  @doc_date smalldatetime,	-- საბუთის თარიღი
  @doc_num int = NULL,		-- საბუთის ნომერი ან კოდი

  @tariff_kind bit = 0,		-- 0 = First currency, 1 = 2nd currency
  
  @rate_kind tinyint = 0,	-- 0 = Bank's rate, 1 = User's rate , 2 = NBG rate

  @channel_id int = 200,	-- არხი, რომლითაც ემატება ეს საბუთი
							-- 200 - ბანკი-კლიენტი
							-- 900 - ინტერნეტ ბანკინგი
  @foreign_id int,			-- გარე ნომერი
							-- ბანკ-კლიენტის შემთხვევაში საბუთის შიდა ნომერი იმ ბაზაში, საიდანაც ემატება.
							-- ინტერნეტ ბანკინგის შემთხვევაში, ???

  @lat bit = 0				-- გამოიტანოს თუ არა შეცდომები ინგლისურად
AS

SET NOCOUNT ON

DECLARE 
	@today smalldatetime,
	@doc_date_in_doc smalldatetime

SET @doc_date_in_doc = @doc_date

SET @today = convert(smalldatetime,floor(convert(real,getdate())))

IF DATEDIFF(dd, @today, @doc_date) > 10
BEGIN
  IF @lat = 0 
       RAISERROR ('<ERR>ÓÀÁÖÈÉÓ ÈÀÒÉÙÉ 10 ÃÙÄÆÄ ÌÄÔÉÈ ÂÀÍÓáÅÀÅÃÄÁÀ ÃÙÄÅÀÍÃÄËÉÓÀÂÀÍ</ERR>',16,1)
  ELSE RAISERROR ('<ERR>Difference between document date and current date is more than 10 days</ERR>',16,1)
  RETURN (3)
END


DECLARE
	@bc_client_id int,
	@owner int,
	@bc_login_flags int,
	@bc_client_flags int,
	@client_type tinyint,
	@client_branch_id int

SELECT @bc_client_id = BC_CLIENT_ID, @bc_login_flags = FLAGS
FROM dbo.BC_LOGINS
WHERE BC_LOGIN_ID = @bc_login_id
IF @@ROWCOUNT = 0
BEGIN
  RAISERROR ('<ERR>INTERNAL ERROR #0003. PLEASE CONTACT ALTA Software Ltd.</ERR>',16,1)
  RETURN (1003)
END

DECLARE @disable_flag int
SET @disable_flag = CASE WHEN @channel_id = 900 THEN 2 ELSE 1 END

/* Check login rights */
IF @bc_login_flags & @disable_flag = 0  /* not internet or BC enabled */ OR 
   @bc_login_flags & 4096 = 0  /* not can_add_conv */ 
BEGIN
  IF @lat = 0 
       RAISERROR ('<ERR>ÈØÅÄÍ ÀÒ ÂÀØÅÈ ÀÌÉÓ Ö×ËÄÁÀ</ERR>',16,1)
  ELSE RAISERROR ('<ERR>You don''t have rignts to do this"</ERR>',16,1)
  RETURN (1000)
END

SELECT @owner = BNK_CLI_OPER_ID, @bc_client_flags = FLAGS, @client_type = CLIENT_TYPE, @client_branch_id = BRANCH_ID
FROM dbo.BC_CLIENTS
WHERE BC_CLIENT_ID = @bc_client_id
IF @@ROWCOUNT = 0
BEGIN
  RAISERROR ('<ERR>INTERNAL ERROR #0004. PLEASE CONTACT ALTA Software Ltd.</ERR>',16,1)
  RETURN (1004)
END

/* Check ClientType */
IF @client_type <> 0
BEGIN
  IF @lat = 0 
       RAISERROR ('<ERR>ÈØÅÄÍ ÀÒ ÂÀØÅÈ ÀÌÉÓ Ö×ËÄÁÀ</ERR>',16,1)
  ELSE RAISERROR ('<ERR>You don''t have rignts to do this"</ERR>',16,1)
  RETURN (1009)
END

/* Check client rights */
IF @bc_client_flags & @disable_flag = 0  /* not internet or BC enabled */
BEGIN
  IF @lat = 0 
       RAISERROR ('<ERR>ÈØÅÄÍ ÀÒ ÂÀØÅÈ ÀÌÉÓ Ö×ËÄÁÀ</ERR>',16,1)
  ELSE RAISERROR ('<ERR>You don''t have rignts to do this"</ERR>',16,1)
  RETURN (1000)
END

DECLARE 
	@r int,
	@d_client_id int,
	@c_client_id int,
	@d_rec_state tinyint,
	@c_rec_state tinyint,
	@debit_id int,
	@credit_id int,
	@debit_branch_id int,
	@credit_branch_id int
	
SELECT @debit_id = LA.ACC_ID, @debit_branch_id = @client_branch_id
FROM dbo.BC_LOGIN_ACC_VIEW LA (NOLOCK)
	INNER JOIN dbo.ACCOUNTS A (NOLOCK) ON A.ACC_ID = LA.ACC_ID
WHERE LA.BC_LOGIN_ID = @bc_login_id AND A.BRANCH_ID = @client_branch_id AND A.ACCOUNT = @debit AND A.ISO = @iso_d

IF @debit_id IS NULL
	SELECT TOP 1 @debit_id = LA.ACC_ID, @debit_branch_id = A.BRANCH_ID
	FROM dbo.BC_LOGIN_ACC_VIEW LA (NOLOCK)
		INNER JOIN dbo.ACCOUNTS A (NOLOCK) ON A.ACC_ID = LA.ACC_ID
	WHERE LA.BC_LOGIN_ID = @bc_login_id AND A.ACCOUNT = @debit AND A.ISO = @iso_d


SELECT @credit_id = LA.ACC_ID, @credit_branch_id = @client_branch_id
FROM dbo.BC_LOGIN_ACC_VIEW LA (NOLOCK)
	INNER JOIN dbo.ACCOUNTS A (NOLOCK) ON A.ACC_ID = LA.ACC_ID
WHERE LA.BC_LOGIN_ID = @bc_login_id AND A.BRANCH_ID = @client_branch_id AND A.ACCOUNT = @credit AND A.ISO = @iso_c

IF @credit_id IS NULL
	SELECT TOP 1 @credit_id = LA.ACC_ID, @credit_branch_id = A.BRANCH_ID
	FROM dbo.BC_LOGIN_ACC_VIEW LA (NOLOCK)
		INNER JOIN dbo.ACCOUNTS A (NOLOCK) ON A.ACC_ID = LA.ACC_ID
	WHERE LA.BC_LOGIN_ID = @bc_login_id AND A.ACCOUNT = @credit AND A.ISO = @iso_c


EXEC @r = dbo.BCC_CHECK_ACC @bc_client_id, @bc_login_id, @debit_id, @lat, 'debit_conv', @disable_flag
IF @@ERROR <> 0 OR @r <> 0 RETURN(1)

SELECT @d_client_id = CLIENT_NO, @d_rec_state = REC_STATE
FROM dbo.ACCOUNTS (NOLOCK)
WHERE ACC_ID = @debit_id

EXEC @r = dbo.BCC_CHECK_ACC @bc_client_id, @bc_login_id, @credit_id, @lat, 'credit_conv', @disable_flag
IF @@ERROR <> 0 OR @r <> 0 RETURN(2)

IF NOT EXISTS(SELECT * FROM dbo.ops_accounts_memo_debit where ACC_ID = @debit_id)
BEGIN
  IF @lat = 0 
       RAISERROR ('<ERR>ÀÌ ÀÍÂÀÒÉÛÉÃÀÍ ÀÒ ÂÀØÅÈ ÂÀÃÀÒÉÝáÅÉÓ Ö×ËÄÁÀ.</ERR>',16,1)
  ELSE RAISERROR ('<ERR>You cannot transfer money from this account.</ERR>',16,1)
  RETURN (1)
END

SELECT @c_client_id = CLIENT_NO, @c_rec_state = REC_STATE
FROM dbo.ACCOUNTS
WHERE ACC_ID = @credit_id

IF (@d_client_id IS NOT NULL OR @c_client_id IS NOT NULL) AND (@c_client_id <> @d_client_id)
BEGIN
  IF @lat = 0 
       RAISERROR('<ERR>ÅÀËÖÔÉÓ ÂÀÌÚÉÃÅÄËÉ ÃÀ ÌÚÉÃÅÄËÉ ÖÍÃÀ ÉÚÏÓ ÄÒÈÉÃÀÉÂÉÅÄ ÊËÉÄÍÔÉ</ERR>',16,1)
  ELSE RAISERROR('<ERR>Seller and buyer of currency must be the same client</ERR>',16,1);
  RETURN (3)
END

IF (@doc_date is null) OR @doc_date < @today OR 
     ((@channel_id = 200) and (@bc_login_flags & 64 = 0)) /* date in conversion docs */
  SET @doc_date = @today

SET @date_changed = 0

IF @channel_id <> 900 /* Not Internet Banking */
  EXEC dbo.BCC_GET_DOC_DATE @bc_login_id, @doc_date OUTPUT, @date_changed OUTPUT


IF @amount_d <= $0.00 OR @amount_c <= $0.00
BEGIN
  IF @lat = 0 
       RAISERROR('<ERR>ÈÀÍáÀ ÖÍÃÀ ÉÚÏÓ ÍÖËÆÄ ÌÄÔÉ</ERR>',16,1)
  ELSE RAISERROR('<ERR>Amount must be more than zero</ERR>',16,1);
  RETURN (3)
END

IF @bc_login_flags & 256 <> 0 /* tariff only in 1st currency */
  SET @tariff_kind = 0

DECLARE 
	@rec_id_2 int, 
	@rec_state tinyint

IF @bc_login_flags & 512 <> 0 AND /* add conversions on level 1. i.e. rec_state = 10 */
   (@channel_id = 200 OR @d_rec_state = 1) AND @date_changed = 0 AND @doc_date = @today
     SET @rec_state = 10
ELSE SET @rec_state = 0

IF @bc_login_flags & 32 = 0 AND @rate_kind = 2 /* NBG rate disabled */
	SET @rate_kind = 1 /* User's rate */

DECLARE
	@rate_items  int,
	@rate_amount money,
	@rate_reverse  bit,
	@rate_info varchar(100),
	@rate_nbg bit

SET @rate_nbg = 0
IF @rate_kind = 2 /* NBG rate */
	SET @rate_nbg = 1

EXEC @r = dbo.BCC_GET_CROSS_RATE_INFO @bc_client_id, @iso_d, @iso_c, @rate_nbg, @rate_amount OUTPUT, @rate_items OUTPUT, @rate_reverse OUTPUT, @doc_date
IF @@ERROR <> 0 OR @r <> 0 RETURN(9)

DECLARE 
	@amount_2 money,
	@tmp_amount money

IF @fix_a <> 0
BEGIN
  IF @rate_reverse = 0
  BEGIN
    SET @tmp_amount = @amount_d * @rate_amount
    SET @amount_2 = @tmp_amount / @rate_items
  END
  ELSE
  BEGIN
    SET @tmp_amount = @amount_d * @rate_items
    SET @amount_2 = @tmp_amount / @rate_amount
  END
END
ELSE
BEGIN
  IF @rate_reverse = 0
  BEGIN
    SET @tmp_amount = @amount_c * @rate_items
    SET @amount_2 = @tmp_amount / @rate_amount
  END
  ELSE
  BEGIN
    SET @tmp_amount = @amount_c * @rate_amount
    SET @amount_2 = @tmp_amount / @rate_items
  END
END
SET @amount_2 = round(@amount_2, 2)

SET @rate_changed = 0

/* Compare @amount_2 and @amount_c or @amount_d */
IF (@fix_a <> 0 AND @amount_2 <> @amount_c) OR
   (@fix_a = 0 AND @amount_2 <> @amount_d)
BEGIN 
  IF @rate_kind = 0 /* Bank's Rate */
  BEGIN
    IF @fix_a <> 0 
         SET @amount_c = @amount_2
    ELSE SET @amount_d = @amount_2
    SET @rate_changed = 1
  END
  ELSE
  IF @rate_kind = 1 /* User's Rate */
  BEGIN
    IF @lat = 0 
         RAISERROR('<ERR>ÁÀÍÊÉÓ ÛÉÃÀ ÊÏÍÅÄÒÓÉÉÓ ÊÖÒÓÉ ÛÄÉÝÅÀËÀ.</ERR>',16,1)
    ELSE RAISERROR('<ERR>Bank''s currency exchange rate changed.</ERR>',16,1);
    RETURN (11)
  END
  ELSE
  IF @rate_kind = 2 /* NBG Rate */
  BEGIN
    IF @lat = 0 
         RAISERROR('<ERR>ÄÒÏÅÍÖËÉ ÁÀÍÊÉÓ ÊÖÒÓÉ ÛÄÉÝÅÀËÀ.</ERR>',16,1)
    ELSE RAISERROR('<ERR>Currency rate of National Bank changed.</ERR>',16,1);
    RETURN (12)
  END
END

DECLARE
	@descrip varchar(150),
	@noputrate int

IF (@doc_date > @today) and (@rate_kind <> 2)
	SET @noputrate = 1
ELSE
	EXEC dbo.GET_SETTING_INT 'OPT_NOPUTRATECONV', @noputrate OUTPUT

IF @noputrate = 0
BEGIN
	IF @rate_reverse = 0
		SET @rate_info = ltrim(str(@rate_items)) + ' ' + @iso_d + ' = ' +  CONVERT(varchar(15),@rate_amount,2) + ' ' + @iso_c
	ELSE SET @rate_info = ltrim(str(@rate_items)) + ' ' + @iso_c + ' = ' +  CONVERT(varchar(15),@rate_amount,2) + ' ' + @iso_d
END

IF (@lat <> 0) OR (@bc_login_flags & 128 <> 0) /* lat descrip in conversion docs */
BEGIN
  IF @noputrate = 0
  BEGIN
    SET @descrip = 'Foreign Exchange (Cross-Rate: ' + @rate_info + ')'
  END
  ELSE
  BEGIN
    SET @descrip = 'Foreign Exchange'
  END
END
ELSE
BEGIN
  IF @noputrate = 0
  BEGIN
    SET @descrip = 'ÊÏÍÅÄÒÓÉÀ (ÊÒÏÓ-ÊÖÒÓÉ: ' + @rate_info + ')'
  END
  ELSE
  BEGIN
    SET @descrip = 'ÊÏÍÅÄÒÓÉÀ'
  END
END

DECLARE @flag int
IF @fix_a <> 0
     SET @flag = 5
ELSE SET @flag = 6

IF EXISTS( SELECT * FROM dbo.OPS_0000 (NOLOCK)
           WHERE BNK_CLI_ID = @bc_login_id AND CHANNEL_ID = @channel_id AND FOREIGN_ID = @foreign_id AND ISO = @iso_d AND AMOUNT = @amount_d)
BEGIN
  IF @lat = 0 
       RAISERROR ('<ERR>ÄÓ ÓÀÁÖÈÉ ÀËÁÀÈ ÖÊÅÄ ÃÀÌÀÔÄÁÖËÉÀ ÁÀÍÊÉÓ ÓÀÁÖÈÄÁÉÓ ÓÉÀÛÉ. ÂÈáÏÅÈ ÂÀÃÀÀÌÏßÌÏÈ.</ERR>',16,1)
  ELSE RAISERROR ('<ERR>This document is likely to be in bank''s directory of documents. Please check again.</ERR>',16,1)
  RETURN (1)
END

DECLARE @op_code TOPCODE
SET @op_code = CASE WHEN @channel_id = 900 THEN 'WBCNV' ELSE 'BCCNV' END

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

EXEC @r = dbo.ADD_CONV_DOC4 
	@rec_id OUTPUT,
	@rec_id_2 OUTPUT,
	@user_id = 8,
	@iso_d = @iso_d,
	@iso_c = @iso_c,
	@amount_d = @amount_d,
	@amount_c = @amount_c,
	@debit_id = @debit_id,
	@credit_id = @credit_id,
	@doc_date = @doc_date,
	@op_code = @op_code,
	@bnk_cli_id = @bc_login_id,
	@doc_num = @doc_num,
	@owner = @owner,
	@dept_no = @client_branch_id,
	@tariff_kind = @tariff_kind,
	@lat_descrip = @lat,
	@is_kassa = 0,
	@descrip1 = @descrip,
	@descrip2 = @descrip,
	@rec_state = @rec_state,
	@rate_items = @rate_items,  
	@rate_amount = @rate_amount,  
	@rate_reverse = @rate_reverse, 
	@rate_flags = @flag,
	@channel_id = @channel_id,
	@foreign_id = @foreign_id,
	@lat = @lat

IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 31 END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN
RETURN (0)
GO
