SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ADD_DOC4]
	@rec_id int OUTPUT,				-- რა შიდა ნომრით დაემატა საბუთი
	@user_id int,					-- ვინ ამატებს საბუთს
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
	@sender_address_lat varchar(105) = null,
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
	@lat bit = 0,			-- გამოიტანოს თუ არა შეცდომები ინგლისურად
	@unblock bit = 0,		-- მოხსნას შესაბამისი ბლოკი თუ არსებიობს, თუ არადა დაარტყას შეცდომა
	@unblock_product_id varchar(20) = null,
	@info_message varchar(255) = null OUTPUT -- შეტყობინება, რომელსაც გამოუტანს მომხმარებელს საბუთის დამატების შემდეგ
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

EXEC @r = dbo.ON_USER_BEFORE_ADD_DOC
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
       RAISERROR ('<ERR>ÞÅÄËÉ ÓÀÌÖÛÀÏ ÈÀÒÉÙÉÈ ÓÀÁÖÈÉÓ ÃÀÌÀÔÄÁÀ ÀÒ ÛÄÉÞËÄÁÀ</ERR>',16,1)
  ELSE RAISERROR ('<ERR>Cannot add documets with an old working date</ERR>',16,1)
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

IF @check_limits = 1
BEGIN
	EXEC @r = dbo.doc_check_user_limits @user_id, @iso, @amount, @doc_type, 0, @rec_state OUTPUT, @lat
	IF @@ERROR <> 0 OR @r <> 0 RETURN 1
END

IF NOT ISNULL(@rec_state, 255) BETWEEN 0 AND 29
	SET @rec_state = 0

IF @channel_id = 50 --  Call center
BEGIN
	EXEC @r = dbo.call_center_check_limits @iso, @debit_id, @credit_id, @amount, @doc_date, @doc_type, @rec_state OUTPUT
	IF @r <> 0 OR @@ERROR <> 0
		RETURN (901)
END

SET @descrip = LTRIM(RTRIM(ISNULL(@descrip,'')))

IF @doc_type BETWEEN 100 AND 119	-- საგადასახადო დავალება
BEGIN
	IF @rec_date IS NULL
		SET @rec_date = convert(smalldatetime,floor(convert(real,getdate())))

	SET @sender_acc_name = LTRIM(RTRIM(ISNULL(@sender_acc_name,'')))
	SET @receiver_acc_name = LTRIM(RTRIM(ISNULL(@receiver_acc_name,'')))

	IF @descrip = ''
	BEGIN
	  IF @lat = 0 
		   RAISERROR ('<ERR>ÃÀÍÉÛÍÖËÄÁÀ ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ</ERR>',16,1)
	  ELSE RAISERROR ('<ERR>Payment detail is not specified</ERR>',16,1)
	  RETURN (201)
	END
	 
    IF @sender_acc_name = ''
	BEGIN
	  IF @lat = 0 
		   RAISERROR ('<ERR>ÂÀÃÀÌáÃÄËÉÓ ÃÀÓÀáÄËÄÁÀ ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ</ERR>',16,1)
	  ELSE RAISERROR ('<ERR>Sender''s name is not specified</ERR>',16,1)
	  RETURN (202)
	END

	IF @receiver_acc_name = ''
	BEGIN
	  IF @lat = 0 
		   RAISERROR ('<ERR>ÌÉÌÙÄÁÉÓ ÃÀÓÀáÄËÄÁÀ ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ</ERR>',16,1)
	  ELSE RAISERROR ('<ERR>Receiver''s name is not specified</ERR>',16,1)
	  RETURN (202)
	END

	IF @doc_type NOT IN (104, 114) -- ÜÀÒÉÝáÅÀ
	BEGIN
		DECLARE @today smalldatetime
		SET @today = convert(smalldatetime,floor(convert(real,getdate())))

		IF DATEDIFF(dd, @today, @doc_date) > 10
		BEGIN
		  IF @lat = 0 
			   RAISERROR ('<ERR>ÂÀÔÀÒÄÁÉÓ ÈÀÒÉÙÉ 10 ÃÙÄÆÄ ÌÄÔÉÈ ÂÀÍÓáÅÀÅÃÄÁÀ ÃÙÄÅÀÍÃÄËÉÓÀÂÀÍ</ERR>',16,1)
		  ELSE RAISERROR ('<ERR>Difference between transaction date and current date is more than 10 days</ERR>',16,1)
		  RETURN (203)
		END

		IF DATEDIFF(dd, @doc_date_in_doc, @doc_date) > 10
		BEGIN
		  IF @lat = 0 
			   RAISERROR ('<ERR>ÂÀÔÀÒÄÁÉÓ ÈÀÒÉÙÉ 10 ÃÙÄÆÄ ÌÄÔÉÈ ÂÀÍÓáÅÀÅÃÄÁÀ ÓÀÁÖÈÉÓ ÈÀÒÉÙÉÓÀÂÀÍ</ERR>',16,1)
		  ELSE RAISERROR ('<ERR>Difference between transaction date and document date is more than 10 days</ERR>',16,1)
		  RETURN (204)
		END
	END
END

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

-- ნაღდი ფულის კონტროლი
DECLARE 
	@cash_amount money,
	@cash_op_type tinyint

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


-------------------------

IF (@cashier IS NULL) AND -- @cashier არ არის მითითებული
	(@doc_type BETWEEN 120 AND 149) AND -- სალაროს საბუთები
	(@rec_state >= 10)
BEGIN
	IF @rec_state < 20 -- ყვითელია
	BEGIN
		IF EXISTS(SELECT * FROM dbo.USERS (NOLOCK) WHERE [USER_ID] = @user_id AND (IS_OPERATOR_CASHIER = 1 OR IS_CASHIER = 1))
			SET @cashier = @user_id
	END
	ELSE
		SET @cashier = @user_id
END
	
-- ნაღდი ფულის კონტროლი

EXEC @r = dbo._INTERNAL_ADD_DOC
  @rec_id = @rec_id OUTPUT,			
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

	INSERT INTO dbo.DOC_DETAILS_PLAT WITH (ROWLOCK) (DOC_REC_ID,SENDER_BANK_CODE,SENDER_ACC,SENDER_TAX_CODE,RECEIVER_BANK_CODE,RECEIVER_ACC,RECEIVER_TAX_CODE,SENDER_BANK_NAME,RECEIVER_BANK_NAME,SENDER_ACC_NAME,RECEIVER_ACC_NAME,POR,REC_DATE,SAXAZKOD,EXTRA_INFO,REF_NUM,TAX_PAYER_NAME,TAX_PAYER_TAX_CODE)
	VALUES (@rec_id,convert(int,@sender_bank_code),@sender_acc,@sender_tax_code,
				  convert(int,@receiver_bank_code),@receiver_acc,@receiver_tax_code,
				  convert(varchar(50),@sender_bank_name),convert(varchar(50),@receiver_bank_name),
				  @sender_acc_name,@receiver_acc_name,@por,@rec_date,@saxazkod,@extra_info,@ref_num,@tax_payer_name,@tax_payer_tax_code)
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 2 END
END
ELSE
IF @doc_type BETWEEN 110 AND 119	-- სავალუტო საგადასახადო დავალება
BEGIN
  INSERT INTO dbo.DOC_DETAILS_VALPLAT WITH (ROWLOCK) (DOC_REC_ID,SENDER_BANK_CODE,SENDER_ACC,RECEIVER_BANK_CODE,RECEIVER_ACC,SENDER_BANK_NAME,RECEIVER_BANK_NAME,SENDER_ACC_NAME,RECEIVER_ACC_NAME,INTERMED_BANK_CODE,INTERMED_BANK_NAME,EXTRA_INFO,SENDER_TAX_CODE,RECEIVER_TAX_CODE,
	SWIFT_TEXT,REF_NUM,COR_BANK_CODE,COR_BANK_NAME,DET_OF_CHARG, EXTRA_INFO_DESCRIP, SENDER_ADDRESS_LAT, RECEIVER_ADDRESS_LAT)
  VALUES (@rec_id,@sender_bank_code,@sender_acc,@receiver_bank_code,@receiver_acc,@sender_bank_name,@receiver_bank_name,@sender_acc_name,@receiver_acc_name,@intermed_bank_code,@intermed_bank_name,@extra_info,@sender_tax_code,@receiver_tax_code,
	@swift_text,@ref_num,@cor_bank_code,@cor_bank_name,@det_of_charg,@extra_info_descrip, @sender_address_lat, @receiver_address_lat)
  IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 3 END
END

IF @doc_type BETWEEN 120 AND 149 OR	-- სალაროს საბუთები
	@doc_type BETWEEN 110 AND 119 OR	-- სავალუტო საგადასახადო დავალება
	@doc_type in (206, 208) -- გარებალანსი
BEGIN
	INSERT INTO dbo.DOC_DETAILS_PASSPORTS WITH (ROWLOCK) (DOC_REC_ID,FIRST_NAME,LAST_NAME,FATHERS_NAME,BIRTH_DATE,BIRTH_PLACE,ADDRESS_JUR,ADDRESS_LAT,COUNTRY,PASSPORT_TYPE_ID,PASSPORT,PERSONAL_ID,REG_ORGAN,PASSPORT_ISSUE_DT,PASSPORT_END_DATE)
	VALUES (@rec_id,@first_name,@last_name,@fathers_name,@birth_date,@birth_place,@address_jur,@address_lat,@country,@passport_type_id,@passport,@personal_id,@reg_organ,@passport_issue_dt,@passport_end_date)
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 4 END
END

IF @doc_type BETWEEN 140 AND 149	-- სალაროს ჩეკი
BEGIN
	DECLARE @chk_id int, @chk_num int

	SET @chk_num = @doc_num
	SELECT @chk_id = CHK_ID 
	FROM dbo.CHK_BOOKS (NOLOCK)
	WHERE CHK_SERIE = @chk_serie AND CHK_NUM_FIRST <= @chk_num AND CHK_NUM_FIRST + CHK_COUNT > @chk_num
	IF @@ROWCOUNT = 0 
	BEGIN 
		RAISERROR('CHECK BOOK NOT FOUND',16,1) 
		IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK 
		RETURN 5
	END

	IF EXISTS(SELECT * FROM dbo.CHK_BOOK_DETAILS (NOLOCK) WHERE CHK_ID = @chk_id AND CHK_NUM = @chk_num)
	BEGIN
		UPDATE dbo.CHK_BOOK_DETAILS WITH (ROWLOCK) 
		SET CHK_STATE = 1, CHK_USE_DATE = @doc_date, [USER_ID] = @user_id
		WHERE CHK_ID = @chk_id AND CHK_NUM = @chk_num
        IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 6 END

		INSERT INTO dbo.CHK_BOOK_DET_CHANGES WITH (ROWLOCK) (CHK_ID,CHK_NUM,[USER_ID],DESCRIP,DOC_REC_ID)
		VALUES (@chk_id, @chk_num, @user_id,'ÂÀÌÏÚÄÍÄÁÖËÉ',@rec_id)
	END
	ELSE
		INSERT INTO dbo.CHK_BOOK_DETAILS WITH (ROWLOCK) (CHK_ID,CHK_NUM,CHK_STATE,CHK_USE_DATE,[USER_ID]) 
		VALUES (@chk_id, @chk_num, 1, @doc_date,@user_id)
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 7 END
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

		@info = @info ,					-- რეალურად გატარდეს, თუ მხოლოდ ინფორმაციაა
		@lat = @lat						-- გამოიტანოს თუ არა შეცდომები ინგლისურად

	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 52 END
END 

IF @unblock <> 0
BEGIN
	DECLARE @block_id int

	SET @fee = ISNULL(@fee, $0.00)

	IF SUBSTRING(@unblock_product_id, 1, 1) = '*' -- First '*' is for group blocking
		SELECT TOP 1 @block_id = BLOCK_ID
		FROM dbo.ACCOUNTS_BLOCKS 
		WHERE ACC_ID = @debit_id AND ISO = @iso AND AMOUNT >= @amount AND IS_ACTIVE = 1 AND BLOCKED_BY_PRODUCT = @unblock_product_id
	ELSE
		SELECT TOP 1 @block_id = BLOCK_ID
		FROM dbo.ACCOUNTS_BLOCKS 
		WHERE ACC_ID = @debit_id AND ISO = @iso AND AMOUNT = @amount AND FEE = @fee AND IS_ACTIVE = 1 AND BLOCKED_BY_PRODUCT = @unblock_product_id

	IF @block_id IS NULL
	BEGIN 
		RAISERROR('ÀÌ ÏÐÄÒÀÝÉÉÓ ÛÄÓÀÁÀÌÉÓÉ ßÉÍÀÓßÀÒ ÃÀÁËÏÊÉËÉ ÈÀÍáÀ ÀÒ ÌÏÉÞÄÁÍÀ',16,1) 
		IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK 
		RETURN 5
	END

	IF SUBSTRING(@unblock_product_id, 1, 1) = '*' -- First '*' is for group blocking
		EXEC @r = dbo.acc_unblock_amount_by_id_partial @acc_id = @debit_id, @block_id = @block_id, @user_id = @user_id, @amount = @amount
	ELSE
		EXEC @r = dbo.acc_unblock_amount_by_id @acc_id = @debit_id, @block_id = @block_id, @user_id = @user_id, @doc_rec_id = @rec_id
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 52 END
END

IF @check_saldo <> 0
BEGIN
	IF @debit_act_pas <> 2 /* not Active account */
	BEGIN
		EXEC @r = dbo.CHECK_SALDO @debit_id, @doc_date, @op_code, @doc_type, @rec_id, @lat
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 53 END
	END

	IF @credit_act_pas = 2 /* Active account */
	BEGIN
		EXEC @r = dbo.CHECK_SALDO @credit_id, @doc_date, @op_code, @doc_type, @rec_id, @lat
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 53 END
	END
END

INSERT INTO dbo.DOC_CHANGES WITH (ROWLOCK) (DOC_REC_ID,[USER_ID],DESCRIP) 
VALUES (@rec_id, @user_id, 'ÓÀÁÖÈÉÓ ÃÀÌÀÔÄÁÀ' + CASE WHEN @user_id = 8 THEN ' (ÁÀÍÊ-ÊËÉÄÍÔÉÈ)' ELSE '' END) /* bank client = 8*/
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 99 END

IF @rec_state >= 10
BEGIN
	EXEC @r = dbo.ON_USER_BEFORE_AUTHORIZE_DOC @rec_id, @user_id, @owner, @rec_state, 0,
		@parent_rec_id,	@dept_no, @doc_type, @doc_date, @doc_date_in_doc, @debit_id, @credit_id, @iso, @amount, @cash_amount,
		@op_code, @doc_num,	@account_extra, @prod_id, @foreign_id, @channel_id,	@relation_id, @cashier, @info, @lat
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

	EXEC @r = dbo.ON_USER_AFTER_AUTHORIZE_DOC @rec_id, @user_id, @rec_state, 0
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
END

EXEC @r = dbo.ON_USER_AFTER_ADD_DOC
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
	@extra_params = @extra_params,
	@info_message = @info_message OUTPUT
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN @@ERROR
GO
