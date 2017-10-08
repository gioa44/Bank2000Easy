SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[UPDATE_DOC4]
	@rec_id int,					-- საბუთის შიდა №
	@uid int = null,				-- საბუთის ბოლოს ცვლილების ნომერი. თუ ნულია, აღარ ვუყურებთ
	@user_id int,					-- ვინ ცვლის საბუთს
	@owner int = NULL,				-- პატრონი (გაჩუმებით = @user_id)
	@doc_type smallint,				-- საბუთის ტიპი
	@doc_date smalldatetime,		-- ტრანზაქციის თარიღი
	@doc_date_in_doc smalldatetime = NULL,	-- საბუთის თარიღი, ან სხვა თარიღი
	@debit_id int,					-- დებეტის ანგარიში
	@credit_id int,					-- კრედიტის ანგარიში
	@iso TISO = 'GEL',				-- ვალუტის კოდი
	@amount money,					-- თანხა
	@rec_state tinyint = 0,			-- სტატუსი
	@descrip varchar(150) = NULL,	-- დანიშნულება
	@op_code TOPCODE = '',			-- ოპერაციის კოდი
	@parent_rec_id int = 0,			-- ზემდგომი საბუთის ნომერი
										--  0: არ ყავს ზემდგომი, არ  ყავს შვილი
										-- -1: ყავს შვილი (იშლება ერთად, ავტორიზდება ერთად)
										-- -2: ყავს შვილი (იშლება ერთად, ავტორიზდება ცალ-ცალკე)
										-- -3: ყავს შვილი (იშლება ცალ-ცალკე, ავტორიზდება ცალ-ცალკე)
	@doc_num int = NULL,			-- საბუთის ნომერი ან კოდი
	@bnk_cli_id int = NULL,			-- ბანკ-კლიენტის მომხმარებლის №
	@account_extra TACCOUNT = NULL,	-- დამატებითი ანგარიშის მისათითებელი ველი
	@dept_no int = null,			-- ფილიალისა და განყოფილების №
	@prod_id int = null,			-- პროდუქტის ნომერი, რომელიც ამატებს ამ საბუთს
	@foreign_id int = null,			-- დამტებითი გარე №
	@channel_id int = 0,			-- არხი, რომლითაც ემატება ეს საბუთი
	@is_suspicious bit = 0,			-- არის თუ არა საეჭვო ეს საბუთი

	@relation_id int = NULL,
	@flags int = 0,

	-- სალაროს საბუთებისათვის

	@cashier int = NULL,
	@chk_serie varchar(4) = NULL,
	@treasury_code varchar(9) = NULL,
	@tax_code_or_pid varchar(11) = NULL,

	-- საგადასახადო დავალებებისათვის

	@por smallint = NULL,

	@sender_bank_code varchar(37) = NULL,
	@sender_bank_name varchar(105) = NULL,
	@sender_acc varchar(37) = NULL,
	@sender_acc_name varchar(105) = NULL,
	@sender_tax_code varchar(11) = NULL,

	@receiver_bank_code varchar(37) = NULL,
	@receiver_bank_name varchar(105) = NULL,
	@receiver_acc varchar(37) = NULL,
	@receiver_acc_name varchar(105) = NULL,
	@receiver_tax_code varchar(11) = NULL,

	@extra_info varchar(250) = NULL,
	@ref_num varchar(32) = null,

	-- ლარის საგადასახადო დავალებებისათვის

	@rec_date smalldatetime = NULL,	-- საგ. დავალების რეგისტრაციის თარიღი
	@saxazkod varchar(9) = NULL,
	@tax_payer_tax_code varchar(11) = NULL, -- გადასახადის გადამხდელის საგადასახადო კოდი
    @tax_payer_name varchar(100) = NULL, -- გადასახადის გადამხდელის დასახელება

	-- სავ. საგადასახადო დავალებებისათვის

	@intermed_bank_code varchar(37) = NULL,
	@intermed_bank_name varchar(105) = NULL,
	@swift_text text = null,
	@cor_bank_code varchar(37) = null,
	@cor_bank_name varchar(105) = null,
	@det_of_charg char(3) = NULL,
	@extra_info_descrip bit = NULL,
	@sender_address_lat varchar(105) = NULL,
	@receiver_address_lat varchar(105) = null,	

	-- სალაროს საბუთებისათვის და სავ. საგადასახადო დავალებებისათვის

	@first_name varchar(50) = null,
	@last_name varchar(50) = null, 
	@fathers_name varchar(50) = null, 
	@birth_date smalldatetime = null, 
	@birth_place varchar(100) = null, 
	@address_jur varchar(100) = null, 
	@address_lat varchar(100) = null,
	@country varchar(2) = null, 
	@passport_type_id tinyint = 0, 
	@passport varchar(50) = null, 
	@personal_id varchar(20) = null,
	@reg_organ varchar(50) = null,
	@passport_issue_dt smalldatetime = null,
	@passport_end_date smalldatetime = null,

	-- სხვა პარამეტრები

	@check_saldo bit = 1,	-- შეამოწმოს თუ არა მინ. ნაშთი
	@add_tariff bit = 1,	-- დაამატოს თუ არა ტარიფის საბუთი
	@check_limits bit = 1,	-- შეამოწმოს თუ არა ლიმიტები
	@info bit = 0,			-- რეალურად გატარდეს, თუ მხოლოდ ინფორმაციაა
	@lat bit = 0			-- გამოიტანოს თუ არა შეცდომები ინგლისურად
AS

SET NOCOUNT ON

IF (@user_id >= 10) AND (SELECT VALS FROM dbo.INI_INT (NOLOCK) WHERE IDS = 'SERVER_STATE') <> 0
BEGIN
	RAISERROR ('ÌÉÌÃÉÍÀÒÄÏÁÓ ÃÙÉÓ ÃÀáÖÒÅÀ/ÂÀáÓÍÀ. ÂÈáÏÅÈ ÃÀÉÝÀÃÏÈ', 16, 1)	
	RETURN 1
END

DECLARE 
	@r int,
	@extra_params xml

SET @extra_params = NULL

EXEC @r = dbo.ON_USER_BEFORE_UPDATE_DOC
	@rec_id = @rec_id,
	@user_id = @user_id OUTPUT,
	@owner = @owner OUTPUT,
	@doc_type = @doc_type OUTPUT,
	@doc_date = @doc_date OUTPUT,
	@doc_date_in_doc = @doc_date_in_doc OUTPUT,
	@debit_id = @debit_id OUTPUT,
	@credit_id = @credit_id OUTPUT,
	@iso = @iso OUTPUT,
	@amount = @amount OUTPUT,
	@rec_state = @rec_state OUTPUT,
	@descrip = @descrip OUTPUT,
	@op_code = @op_code OUTPUT,
	@parent_rec_id = @parent_rec_id OUTPUT,
	@doc_num = @doc_num OUTPUT,
	@bnk_cli_id = @bnk_cli_id OUTPUT,
	@account_extra = @account_extra OUTPUT,
	@dept_no = @dept_no OUTPUT,
	@prod_id = @prod_id OUTPUT,
	@foreign_id = @foreign_id OUTPUT,
	@channel_id = @channel_id OUTPUT,
	@is_suspicious = @is_suspicious OUTPUT,

	@relation_id = @relation_id OUTPUT,
	@flags = @flags OUTPUT,

	@cashier = @cashier OUTPUT,
	@chk_serie = @chk_serie OUTPUT,
	@treasury_code = @treasury_code OUTPUT,
	@tax_code_or_pid = @tax_code_or_pid OUTPUT,

	@sender_bank_code = @sender_bank_code OUTPUT,
	@sender_bank_name = @sender_bank_name OUTPUT,
	@sender_acc = @sender_acc OUTPUT,
	@sender_acc_name = @sender_acc_name OUTPUT,
	@sender_tax_code = @sender_tax_code OUTPUT,

	@receiver_bank_code = @receiver_bank_code OUTPUT,
	@receiver_bank_name = @receiver_bank_name OUTPUT,
	@receiver_acc = @receiver_acc OUTPUT,
	@receiver_acc_name = @receiver_acc_name OUTPUT,
	@receiver_tax_code = @receiver_tax_code OUTPUT,

	@extra_info = @extra_info OUTPUT,
	@ref_num = @ref_num OUTPUT,

	@rec_date = @rec_date OUTPUT,
	@saxazkod = @saxazkod OUTPUT,

	@intermed_bank_code = @intermed_bank_code OUTPUT,
	@intermed_bank_name = @intermed_bank_name OUTPUT,
	@swift_text = @swift_text OUTPUT,
	@cor_bank_code = @cor_bank_code OUTPUT,
	@cor_bank_name = @cor_bank_name OUTPUT,
	@det_of_charg = @det_of_charg OUTPUT,
	@extra_info_descrip = @extra_info_descrip OUTPUT,

	@first_name = @first_name OUTPUT,
	@last_name = @last_name OUTPUT,
	@fathers_name = @fathers_name OUTPUT,
	@birth_date = @birth_date OUTPUT,
	@birth_place = @birth_place OUTPUT,
	@address_jur = @address_jur OUTPUT,
	@address_lat = @address_lat OUTPUT,
	@country = @country OUTPUT,
	@passport_type_id = @passport_type_id OUTPUT,
	@passport = @passport OUTPUT,
	@personal_id = @personal_id OUTPUT,
	@reg_organ = @reg_organ OUTPUT,
	@passport_issue_dt = @passport_issue_dt OUTPUT,
	@passport_end_date = @passport_end_date OUTPUT,

	@check_saldo = @check_saldo OUTPUT,
	@add_tariff = @add_tariff OUTPUT,
	@info = @info,
	@lat = @lat,
	@extra_params = @extra_params OUTPUT
IF @@ERROR <> 0 OR @r <> 0 RETURN 1

IF @owner IS NULL 
  SET @owner = @user_id

SET @doc_date = convert(smalldatetime,floor(convert(real,@doc_date)))

IF @doc_date < dbo.bank_work_date () AND dbo.sys_has_right(@user_id, 100, 8) = 0
BEGIN
  IF @lat = 0 
       RAISERROR ('<ERR>ÞÅÄËÉ ÓÀÌÖÛÀÏ ÈÀÒÉÙÉÈ ÓÀÁÖÈÉÓ ÛÄÝÅËÀ ÀÒ ÛÄÉÞËÄÁÀ</ERR>',16,1)
  ELSE RAISERROR ('<ERR>Cannot modify documets with an old working date</ERR>',16,1)
  RETURN (3)
END

IF @dept_no IS NULL
	SET @dept_no = dbo.user_dept_no(@user_id)

DECLARE 
	@debit_iso TISO,
	@credit_iso TISO,
	@debit_act_pas tinyint,
	@debit_is_offbalance bit,
	@credit_act_pas tinyint,
	@credit_is_offbalance bit

SELECT @debit_iso = ISO, @debit_act_pas = ACT_PAS, @debit_is_offbalance = IS_OFFBALANCE
FROM dbo.ACCOUNTS (NOLOCK)
WHERE ACC_ID = @debit_id

SELECT @credit_iso = ISO, @credit_act_pas = ACT_PAS, @credit_is_offbalance = IS_OFFBALANCE
FROM dbo.ACCOUNTS (NOLOCK)
WHERE ACC_ID = @credit_id

IF @debit_is_offbalance <> @credit_is_offbalance
BEGIN
	IF @lat = 0 
		RAISERROR ('<ERR>ÁÀËÀÍÓÖÒÓÀ ÃÀ ÂÀÒÄÁÀËÀÍÓÖÒ ÀÍÂÀÒÉÛÄÁÓ ÛÏÒÉÓ ÂÀÔÀÒÄÁÀ ÀÒ ÛÄÉÞËÄÁÀ</ERR>',16,1)
	ELSE RAISERROR ('<ERR>Transaction between balance and offbalance accounts is prohibited</ERR>',16,1)
	RETURN (301)
END

IF @debit_iso <> @credit_iso
BEGIN
	IF @lat = 0 
		RAISERROR ('<ERR>ÃÄÁÄÔÉ ÃÀ ÊÒÄÃÉÔÉÓ ÀÍÂÀÒÉÛÉ ÓáÅÀÃÀÓáÅÀ ÅÀËÖÔÀÛÉÀ</ERR>',16,1)
	ELSE RAISERROR ('<ERR>Debit and Credit accounts are in different currency</ERR>',16,1)
	RETURN (301)
END

IF @debit_iso <> @iso
BEGIN
	IF @lat = 0 
		RAISERROR ('<ERR>ÌÉÈÉÈÄÁÖËÉ ÅÀËÖÔÀ ÀÒ ÄÌÈáÅÄÅÀ ÀÍÂÀÒÉÛÄÁÉÓ ÅÀËÖÔÀÓ</ERR>',16,1)
	ELSE RAISERROR ('<ERR>Supplied currency differs from accounts''s currency</ERR>',16,1)
	RETURN (301)
END

DECLARE
	@cash_amount money,

	@old_debit_id int,
	@old_credit_id int,
	@old_amount money,
	@old_rec_state tinyint,
	@old_doc_type smallint,
	@old_dept_no int,
	@old_op_code TOPCODE,
	@old_chk_serie varchar(4),
	@old_doc_num int,
	@old_doc_date smalldatetime,
	@old_parent_rec_id int,
	@old_account_extra TACCOUNT,
	@old_iso TISO

SELECT @old_debit_id = DEBIT_ID, @old_credit_id = CREDIT_ID, @old_amount = AMOUNT, @old_iso = ISO,
		@old_rec_state = REC_STATE, @old_doc_type = DOC_TYPE, @cash_amount = ISNULL(CASH_AMOUNT, $0.00),
		@old_doc_num = DOC_NUM, @old_chk_serie = CHK_SERIE, @old_doc_date = DOC_DATE, 
		@old_parent_rec_id = PARENT_REC_ID, @old_dept_no = DEPT_NO, @old_op_code = OP_CODE, @old_account_extra = ACCOUNT_EXTRA
FROM dbo.OPS_0000
WHERE REC_ID = @rec_id AND (@uid IS NULL OR UID = @uid)

IF @@ROWCOUNT = 0
BEGIN
  IF @lat = 0 
       RAISERROR ('<ERR>ÓÀÁÖÈÉ ÀÒ ÌÏÉÞÄÁÍÀ, ÀÍ ÛÄÝÅËÉËÉÀ ÓáÅÀ ÌÏÌáÌÀÒÄÁËÉÓ ÌÉÄÒ</ERR>',16,1)
  ELSE RAISERROR ('<ERR>Cannot find document or changed by another user</ERR>',16,1)
  RETURN (3)
END

IF @parent_rec_id < 0
	SET @parent_rec_id = 0

IF @check_limits = 1
BEGIN
	DECLARE @limit_amount money
	IF @old_amount > @amount
		SET @limit_amount = @old_amount
	ELSE
		SET @limit_amount = @amount
	EXEC @r = dbo.doc_check_user_limits @user_id, @old_iso, @limit_amount, @old_doc_type, 1, @old_rec_state OUTPUT, @lat
	IF @@ERROR <> 0 OR @r <> 0 RETURN 1
END

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END


-- ნაღდი ფულის კონტროლი

-- წაშლა

DECLARE 
	@cash_op_type tinyint

SET @cash_amount = ABS(@cash_amount)
SET @cash_op_type = dbo.ops_get_cash_op_type (@old_op_code, @old_doc_type)

IF @cash_op_type IN (1, 3)
BEGIN
	IF @cash_amount <> $0.00
	BEGIN
		UPDATE dbo.ACCOUNTS_DETAILS WITH (ROWLOCK)
		SET AMOUNT_KAS_DELTA = ISNULL(AMOUNT_KAS_DELTA, $0.000) + @cash_amount
		WHERE ACC_ID = @old_debit_id
		IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
	END
END

IF @cash_op_type IN (2, 3)
BEGIN
	IF (@old_rec_state >= 10) AND (@cash_amount <> $0.0000)
	BEGIN
		UPDATE dbo.ACCOUNTS_DETAILS WITH (ROWLOCK)
		SET AMOUNT_KAS_DELTA = ISNULL(AMOUNT_KAS_DELTA, $0.000) - @cash_amount
		WHERE ACC_ID = @old_credit_id
		IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
	END
END

-- დამატება

SET @cash_amount = $0.00

SET @cash_op_type = dbo.ops_get_cash_op_type (@op_code, @doc_type)

IF @cash_op_type IN (1, 3)
BEGIN
	UPDATE dbo.ACCOUNTS_DETAILS WITH (ROWLOCK)
	SET @cash_amount = CASE WHEN ISNULL(AMOUNT_KAS_DELTA, $0.000) > @amount THEN @amount ELSE ISNULL(AMOUNT_KAS_DELTA, $0.000) END,
		AMOUNT_KAS_DELTA = ISNULL(AMOUNT_KAS_DELTA, $0.000) - @cash_amount
	WHERE ACC_ID = @debit_id AND ISNULL(AMOUNT_KAS_DELTA, $0.000) <> $0.00
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
END

IF @cash_op_type IN (2, 3)
BEGIN
	IF @cash_op_type = 2 
		SET @cash_amount = @amount 
	
	IF (@rec_state >= 10) AND (@cash_amount <> $0.00)
	BEGIN
		UPDATE dbo.ACCOUNTS_DETAILS WITH (ROWLOCK)
		SET AMOUNT_KAS_DELTA = ISNULL(AMOUNT_KAS_DELTA, $0.000) + @cash_amount
		WHERE ACC_ID = @credit_id
		IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
	END
END

-- ნაღდი ფულის კონტროლი

IF @add_tariff = 1 AND
	(@old_amount <> @amount OR @old_debit_id <> @debit_id OR @old_credit_id <> @credit_id OR
	@old_doc_date <> @doc_date OR @old_dept_no <> @dept_no OR @old_op_code <> @op_code OR @old_account_extra <> @account_extra) OR
	(@old_doc_num <> @doc_num)
	SET @add_tariff = 1
ELSE
BEGIN
	SET @add_tariff = 0
	SET @parent_rec_id = @old_parent_rec_id
END


EXEC @r = dbo._INTERNAL_UPDATE_DOC
  @rec_id = @rec_id,
  @owner = @owner,
  @doc_type = @doc_type,
  @doc_date = @doc_date,
  @doc_date_in_doc = @doc_date_in_doc,
  @debit_id = @debit_id,
  @credit_id = @credit_id,
  @iso = @iso,
  @amount = @amount,
  @rec_state = @rec_state,
  @descrip = @descrip,
  @op_code = @op_code,
  @parent_rec_id = @parent_rec_id,
  @doc_num = @doc_num,
  @bnk_cli_id = @bnk_cli_id,
  @account_extra = @account_extra,
  @dept_no = @dept_no,
  @prod_id = @prod_id,
  @foreign_id = @foreign_id,
  @channel_id = @channel_id,
  @is_suspicious = @is_suspicious,
  @cash_amount = @cash_amount,
  @cashier = @cashier,
  @chk_serie = @chk_serie,
  @treasury_code = @treasury_code,
  @tax_code_or_pid = @tax_code_or_pid,
  @relation_id = @relation_id,
  @flags = @flags,
  @lat = @lat
IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 31 END

IF @doc_type BETWEEN 100 AND 109	-- საგადასახადო დავალება
BEGIN
	IF @receiver_bank_code = '220101222'
	BEGIN
		IF RTRIM(ISNULL(@tax_payer_name, '')) = ''
		BEGIN
			SET @tax_payer_name = @sender_acc_name
			SET @tax_payer_tax_code = @sender_tax_code
		END
	END
	ELSE
	BEGIN
		SET @tax_payer_name = null
		SET @tax_payer_tax_code = null
		SET @saxazkod = null
	END

	UPDATE dbo.DOC_DETAILS_PLAT WITH (ROWLOCK)
	SET 
		SENDER_BANK_CODE = convert(int,@sender_bank_code),
		SENDER_ACC = @sender_acc,
		SENDER_TAX_CODE = @sender_tax_code,
		RECEIVER_BANK_CODE = convert(int,@receiver_bank_code),
		RECEIVER_ACC = @receiver_acc,
		RECEIVER_TAX_CODE = @receiver_tax_code,
		SENDER_BANK_NAME = convert(varchar(50),@sender_bank_name),
		RECEIVER_BANK_NAME = convert(varchar(50),@receiver_bank_name),
		SENDER_ACC_NAME = @sender_acc_name,
		RECEIVER_ACC_NAME = @receiver_acc_name,
		POR = @por,
		REC_DATE = @rec_date,
		SAXAZKOD = @saxazkod,
		TAX_PAYER_TAX_CODE = @tax_payer_tax_code,
		TAX_PAYER_NAME = @tax_payer_name,
		EXTRA_INFO = @extra_info,
		REF_NUM = @ref_num
	WHERE DOC_REC_ID = @rec_id
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 2 END
END
ELSE
IF @doc_type BETWEEN 110 AND 119		-- სავალუტო საგადასახადო დავალება
BEGIN
	UPDATE dbo.DOC_DETAILS_VALPLAT WITH (ROWLOCK)
	SET
		SENDER_BANK_CODE = @sender_bank_code,
		SENDER_ACC = @sender_acc,
		RECEIVER_BANK_CODE = @receiver_bank_code,
		RECEIVER_ACC = @receiver_acc,
		SENDER_BANK_NAME = @sender_bank_name,
		RECEIVER_BANK_NAME = @receiver_bank_name,
		SENDER_ACC_NAME = @sender_acc_name,
		RECEIVER_ACC_NAME = @receiver_acc_name,
		INTERMED_BANK_CODE = @intermed_bank_code,
		INTERMED_BANK_NAME = @intermed_bank_name,
		EXTRA_INFO = @extra_info,
		SENDER_TAX_CODE = @sender_tax_code,
		RECEIVER_TAX_CODE = @receiver_tax_code,
--		SWIFT_TEXT = @swift_text,
		REF_NUM = @ref_num,
		COR_BANK_CODE = @cor_bank_code,
		COR_BANK_NAME = @cor_bank_name,
		DET_OF_CHARG = @det_of_charg,
		EXTRA_INFO_DESCRIP = @extra_info_descrip,
		SENDER_ADDRESS_LAT = @sender_address_lat,
		RECEIVER_ADDRESS_LAT = @receiver_address_lat
	WHERE DOC_REC_ID = @rec_id
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 3 END
END

IF @doc_type BETWEEN 120 AND 149 OR	-- სალაროს საბუთები
	@doc_type BETWEEN 110 AND 119 OR	-- სავალუტო საგადასახადო დავალება
	@doc_type in (206, 208) -- გარებალანსი
BEGIN
	UPDATE dbo.DOC_DETAILS_PASSPORTS WITH (ROWLOCK)
	SET
		FIRST_NAME = @first_name,
		LAST_NAME = @last_name,
		FATHERS_NAME = @fathers_name,
		BIRTH_DATE = @birth_date,
		BIRTH_PLACE = @birth_place,
		ADDRESS_JUR = @address_jur,
		ADDRESS_LAT = @address_lat,
		COUNTRY = @country,
		PASSPORT_TYPE_ID = @passport_type_id,
		PASSPORT = @passport,
		PERSONAL_ID = @personal_id,
		REG_ORGAN = @reg_organ,
		PASSPORT_ISSUE_DT = @passport_issue_dt,
		PASSPORT_END_DATE = @passport_end_date
	WHERE DOC_REC_ID = @rec_id	
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 5 END
END


IF @doc_type BETWEEN 140 AND 149	-- სალაროს ჩეკი
BEGIN
	DECLARE @chk_id int, @chk_num int

	SET @chk_num = @old_doc_num

	SELECT @chk_id = CHK_ID 
	FROM dbo.CHK_BOOKS (NOLOCK)
	WHERE CHK_SERIE = @old_chk_serie AND CHK_NUM_FIRST <= @chk_num AND CHK_NUM_FIRST + CHK_COUNT > @chk_num
    IF @@ROWCOUNT = 0 
	BEGIN 
		RAISERROR('OLD CHECK BOOK NOT FOUND',16,1) 
		IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK 
		RETURN 6
	END

	IF NOT EXISTS(
		SELECT * 
		FROM dbo.OPS_0000 D WITH (NOLOCK)
		WHERE D.DOC_DATE = @doc_date AND D.CHK_SERIE = @old_chk_serie AND D.DOC_NUM = @chk_num)
    BEGIN
        UPDATE dbo.CHK_BOOK_DETAILS WITH (ROWLOCK)
		SET CHK_STATE = 0, /*CHK_USE_DATE = @old_doc_date,*/ [USER_ID] = @user_id
		WHERE CHK_ID = @chk_id AND CHK_NUM = @chk_num
		IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 7 END
        
		INSERT INTO dbo.CHK_BOOK_DET_CHANGES WITH (ROWLOCK) (CHK_ID,CHK_NUM,[USER_ID],DESCRIP,DOC_REC_ID) 
		VALUES (@chk_id,@chk_num,@user_id,'ÂÀÌÏÖÚÄÍÄÁÄËÉ',@rec_id);
		IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 8 END
	END

	SET @chk_num = @doc_num

	SELECT @chk_id = CHK_ID 
	FROM dbo.CHK_BOOKS (NOLOCK)
	WHERE CHK_SERIE = @chk_serie AND CHK_NUM_FIRST <= @chk_num AND CHK_NUM_FIRST + CHK_COUNT > @chk_num
	IF @@ROWCOUNT = 0 
	BEGIN 
		RAISERROR('CHECK BOOK NOT FOUND',16,1) 
		IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK 
		RETURN 9
	END

	IF EXISTS(SELECT * FROM dbo.CHK_BOOK_DETAILS (NOLOCK) WHERE CHK_ID = @chk_id AND CHK_NUM = @chk_num)
	BEGIN
		UPDATE dbo.CHK_BOOK_DETAILS WITH (ROWLOCK)
		SET CHK_STATE = 1, CHK_USE_DATE = @doc_date, [USER_ID] = @user_id
		WHERE CHK_ID = @chk_id AND CHK_NUM = @chk_num
		IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 10 END
        
		INSERT INTO dbo.CHK_BOOK_DET_CHANGES WITH (ROWLOCK) (CHK_ID,CHK_NUM,[USER_ID],DESCRIP,DOC_REC_ID)
		VALUES (@chk_id, @chk_num, @user_id,'ÂÀÌÏÚÄÍÄÁÖËÉ',@rec_id)
	END
	ELSE
		INSERT INTO dbo.CHK_BOOK_DETAILS WITH (ROWLOCK) (CHK_ID,CHK_NUM,CHK_STATE,CHK_USE_DATE,[USER_ID]) 
		VALUES (@chk_id, @chk_num, 1, @doc_date,@user_id)
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 11 END
END

IF @old_parent_rec_id IN (-1, -2)
BEGIN
	DELETE FROM dbo.OPS_0000 WITH (ROWLOCK)
	WHERE REC_ID > @rec_id AND PARENT_REC_ID = @rec_id AND (@add_tariff = 1 AND DOC_TYPE = 12)
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 12 END
END

DECLARE
	@tariff_rec_id int,
	@fee money

IF @add_tariff <> 0
BEGIN
	EXEC @r = dbo.add_tariff_doc
		@doc_rec_id = @rec_id, 
		@tar_kind = 0,					-- 0 - ჩვეულებრივი საბუთი, 1 - კონვერტაცია. ტარიფის აღება 1–ი საბუთიდან , 2 – კონვერტაცია. ტარიფის აღება 2–ე საბუთიდან 
		@fee_rec_id = @tariff_rec_id OUTPUT,	-- აბრუნებს დამატებული საბუთის REC_ID–ს
		@fee_amount = @fee OUTPUT,		-- აბრუნებს დამატებული საბუთის თანხას (ტარიფის თანხას)

		@user_id = @user_id,			-- ვინ ამატებს საბუთს
		@owner = @owner,				-- პატრონი (გაჩუმებით = @user_id)
		@dept_no = @dept_no,			-- ფილიალისა და განყოფილების №

		@rec_state = @rec_state,		-- სტატუსი

		@doc_type = @doc_type,			-- საბუთის ტიპი
		@doc_date = @doc_date,			-- ტრანზაქციის თარიღი

		@debit_id = @debit_id,			-- დებეტის ანგარიში
		@credit_id = @credit_id,		-- კრედიტის ანგარიში
		@iso = @iso,					-- ვალუტის კოდი
		@amount = @amount,				-- თანხა
		@amount2 = null,
		@cash_amount = @cash_amount,	-- სალაროს დასაბეგრი თანხა
		@op_code = @op_code,			-- ოპერაციის კოდი
		@doc_num = @doc_num,			-- საბუთის ნომერი ან კოდი

		@account_extra = @account_extra,	-- დამატებითი ანგარიშის მისათითებელი ველი
		@prod_id = @prod_id,			-- პროდუქტის ნომერი, რომელიც ამატებს ამ საბუთს
		@foreign_id = @foreign_id,		-- დამატებითი გარე №
		@channel_id = @channel_id,		-- არხი, რომლითაც ემატება ეს საბუთი
		@relation_id = @relation_id,

		@cashier = @cashier,
		@receiver_bank_code = @receiver_bank_code,
		@det_of_charg = @det_of_charg,
		@rate_flags = NULL,

		@info = @info,					-- რეალურად გატარდეს, თუ მხოლოდ ინფორმაციაა
		@lat = @lat						-- გამოიტანოს თუ არა შეცდომები ინგლისურად

	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 52 END
END 

IF @check_saldo <> 0
BEGIN
	-- Check for old Debit

	IF @old_debit_id <> @debit_id AND @old_debit_id <> @credit_id	-- თუ აღარ მონაწილეობს ოპერაციაში
	BEGIN
		DECLARE @old_debit_act_pas tinyint
		SET @old_debit_act_pas = dbo.acc_get_act_pas (@old_debit_id)
		IF @old_debit_act_pas = 2 /* Active account */
		BEGIN
			EXEC @r = dbo.CHECK_SALDO @old_debit_id, @doc_date, @op_code, @doc_type, @rec_id, @lat
			IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 53 END
		END
	END
	
	-- Check for old Credit

	IF @old_credit_id <> @credit_id AND @old_credit_id <> @debit_id	-- თუ აღარ მონაწილეობს ოპერაციაში
	BEGIN
		DECLARE @old_credit_act_pas tinyint
		SET @old_credit_act_pas = dbo.acc_get_act_pas (@old_credit_id)
		IF @old_credit_act_pas <> 2 /* not Active account */
		BEGIN
			EXEC @r = dbo.CHECK_SALDO @old_credit_id, @doc_date, @op_code, @doc_type, @rec_id, @lat
			IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 53 END
		END
	END

	-- Check for new Debit

	IF (@debit_id <> @old_debit_id) OR
		((@old_amount < @amount AND @debit_act_pas <> 2 /* not Active account */) OR
			(@old_amount > @amount AND @debit_act_pas = 2 /* Active account */))
	BEGIN
		EXEC @r = dbo.CHECK_SALDO @debit_id, @doc_date, @op_code, @doc_type, @rec_id, @lat
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 53 END
	END

	-- Check for new Credit

	IF (@credit_id <> @old_credit_id) OR
		((@old_amount > @amount AND @credit_act_pas <> 2 /* not Active account */) OR
		(@old_amount < @amount AND @debit_act_pas = 2 /* Active account */))
	BEGIN
		EXEC @r = dbo.CHECK_SALDO @credit_id, @doc_date, @op_code, @doc_type, @rec_id, @lat
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 53 END
	END
END

EXEC @r = dbo.ON_USER_AFTER_UPDATE_DOC
	@rec_id = @rec_id,
	@user_id = @user_id,
	@owner = @owner,
	@doc_type = @doc_type,
	@doc_date = @doc_date,
	@doc_date_in_doc = @doc_date_in_doc,
	@debit_id = @debit_id,
	@credit_id = @credit_id,
	@iso = @iso,
	@amount = @amount,
	@rec_state = @rec_state,
	@descrip = @descrip,
	@op_code = @op_code,
	@parent_rec_id = @parent_rec_id,
	@doc_num = @doc_num,
	@bnk_cli_id = @bnk_cli_id,
	@account_extra = @account_extra,
	@dept_no = @dept_no,
	@prod_id = @prod_id,
	@foreign_id = @foreign_id,
	@channel_id = @channel_id,
	@is_suspicious = @is_suspicious,

	@relation_id = @relation_id,
	@flags = @flags,

	@cashier = @cashier,
	@chk_serie = @chk_serie,
	@treasury_code = @treasury_code,
	@tax_code_or_pid = @tax_code_or_pid,

	@sender_bank_code = @sender_bank_code,
	@sender_bank_name = @sender_bank_name,
	@sender_acc = @sender_acc,
	@sender_acc_name = @sender_acc_name,
	@sender_tax_code = @sender_tax_code,

	@receiver_bank_code = @receiver_bank_code,
	@receiver_bank_name = @receiver_bank_name,
	@receiver_acc = @receiver_acc,
	@receiver_acc_name = @receiver_acc_name,
	@receiver_tax_code = @receiver_tax_code,

	@extra_info = @extra_info,
	@ref_num = @ref_num,

	@rec_date = @rec_date,
	@saxazkod = @saxazkod,

	@intermed_bank_code = @intermed_bank_code,
	@intermed_bank_name = @intermed_bank_name,
	@swift_text = @swift_text,
	@cor_bank_code = @cor_bank_code,
	@cor_bank_name = @cor_bank_name,
	@det_of_charg = @det_of_charg,
	@extra_info_descrip = @extra_info_descrip,

	@first_name = @first_name,
	@last_name = @last_name,
	@fathers_name = @fathers_name,
	@birth_date = @birth_date,
	@birth_place = @birth_place,
	@address_jur = @address_jur,
	@address_lat = @address_lat,
	@country = @country,
	@passport_type_id = @passport_type_id,
	@passport = @passport,
	@personal_id = @personal_id,
	@reg_organ = @reg_organ,
	@passport_issue_dt = @passport_issue_dt,
	@passport_end_date = @passport_end_date,

	@check_saldo = @check_saldo,
	@add_tariff = @add_tariff,
	@info = @info,
	@lat = @lat,
	@extra_params = @extra_params
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN @@ERROR
GO
