SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ADD_CONV_DOC4]
  @rec_id_1 int OUTPUT,        
  @rec_id_2 int OUTPUT,        
  @user_id int,                
  @owner int = NULL,        
  @iso_d TISO,              
  @iso_c TISO,              
  @amount_d money,          
  @amount_c money,   
  @debit_id int,
  @credit_id int,
  @doc_date smalldatetime,   
  @op_code TOPCODE = 'FX',   
  @doc_num int = NULL,   
  @account_extra TACCOUNT = NULL,   

  @is_kassa bit = 0,   
  
  @descrip1 varchar(150),   
  @descrip2 varchar(150),   
  @rec_state tinyint = 0,   
  @bnk_cli_id int = null,   
  @par_rec_id int = -1,   

  @dept_no int = null,   
  @prod_id int = null,   
  @foreign_id int = null,
  @channel_id int = 0,   
  @is_suspicious bit = 0,   

  @relation_id int = NULL,
  @flags int = 0,

  @rate_items int = Null,
  @rate_amount money = Null,
  @rate_reverse bit = 0,
  @rate_flags int = 0,
  @tariff_kind bit = 0,
  @lat_descrip bit = 0,

  @client_no int = NULL,
  @rate_client_no int = NULL,

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

  @doc_type1 smallint = null,
  @doc_type2 smallint = null,

  @check_saldo bit = 1,   
  @add_tariff bit = 1,   
  @info bit = 0,   
  @lat bit = 0   
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

EXEC @r = dbo.ON_USER_BEFORE_ADD_CONV_DOC
	@user_id = @user_id OUTPUT,
	@owner = @owner OUTPUT,
	@iso_d = @iso_d OUTPUT,
	@iso_c = @iso_c OUTPUT,

	@amount_d = @amount_d OUTPUT,
	@amount_c = @amount_c OUTPUT,
	@debit_id = @debit_id OUTPUT,
	@credit_id = @credit_id OUTPUT,
	@doc_date = @doc_date OUTPUT,
	@op_code = @op_code OUTPUT,
	@doc_num = @doc_num OUTPUT,
	@account_extra = @account_extra OUTPUT,

	@is_kassa = @is_kassa OUTPUT,
  
	@descrip1 = @descrip1 OUTPUT,
	@descrip2 = @descrip2 OUTPUT,
	@rec_state = @rec_state OUTPUT,
	@bnk_cli_id = @bnk_cli_id OUTPUT,
	@par_rec_id = @par_rec_id OUTPUT,

	@dept_no = @dept_no OUTPUT,
	@prod_id = @prod_id OUTPUT,
	@foreign_id = @foreign_id OUTPUT,
	@channel_id = @channel_id OUTPUT,
	@is_suspicious = @is_suspicious OUTPUT,

	@relation_id = @relation_id OUTPUT,
	@flags = @flags OUTPUT,

	@rate_items = @rate_items OUTPUT,
	@rate_amount = @rate_amount OUTPUT,
	@rate_reverse = @rate_reverse OUTPUT,
	@rate_flags = @rate_flags OUTPUT,
	@tariff_kind = @tariff_kind OUTPUT,
	@lat_descrip = @lat_descrip OUTPUT,

	@client_no = @client_no OUTPUT,
	@rate_client_no = @rate_client_no OUTPUT,

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

	@doc_type1 = @doc_type1 OUTPUT,
	@doc_type2 = @doc_type2 OUTPUT,

	@check_saldo = @check_saldo OUTPUT,
	@add_tariff = @add_tariff OUTPUT,
	@info = @info,
	@lat = @lat,
	@extra_params = @extra_params OUTPUT
IF @@ERROR <> 0 OR @r <> 0 RETURN 1

IF @owner IS NULL 
  SET @owner = @user_id

IF @iso_d = @iso_c
BEGIN
  IF @lat = 0 
       RAISERROR ('<ERR>ÅÀËÖÔÉÓ ÊÏÃÄÁÉ ÀÒ ÛÄÉÞËÄÁÀ ÉÚÏÓ ÄÒÈÍÀÉÒÉ</ERR>',16,1)
  ELSE RAISERROR ('<ERR>Currency codes cannot be the same"</ERR>',16,1)
  RETURN (11)
END

IF @doc_date < dbo.bank_work_date () AND dbo.sys_has_right(@user_id, 100, 8) = 0
BEGIN
  IF @lat = 0 
       RAISERROR ('<ERR>ÞÅÄËÉ ÓÀÌÖÛÀÏ ÈÀÒÉÙÉÈ ÓÀÁÖÈÉÓ ÃÀÌÀÔÄÁÀ ÀÒ ÛÄÉÞËÄÁÀ</ERR>',16,1)
  ELSE RAISERROR ('<ERR>Cannot add documets with an old working date</ERR>',16,1)
  RETURN (3)
END

DECLARE @branch_id int

IF @dept_no IS NULL
    SET @dept_no = dbo.user_dept_no(@user_id)
SET @branch_id = dbo.dept_branch_id(@dept_no)

DECLARE
    @tmp_rate_amount1 float,
    @tmp_rate_amount2 float

IF @rate_items IS NULL OR @rate_amount IS NULL
BEGIN
    SET @rate_items = 1
    IF @amount_c >= @amount_d
        SET @rate_amount = convert(money, @amount_c / @amount_d)
    ELSE
    BEGIN
        SET @rate_amount = convert(money, @amount_d / @amount_c)
        SET @rate_reverse = 1
    END
END

DECLARE
	@head_branch_id int,
    @acc_906_gel TACCOUNT,
    @acc_906_val TACCOUNT,
    @acc_19a TACCOUNT,
    @acc_19p TACCOUNT,
	@acc_906_cur TACCOUNT,
	@use_head_conv_income_acc int

SET @head_branch_id = dbo.bank_head_branch_id()

EXEC dbo.GET_SETTING_ACC 'CONV_ACC_2601', @acc_906_gel OUTPUT
EXEC dbo.GET_SETTING_ACC 'CONV_ACC_2611', @acc_906_val OUTPUT

EXEC dbo.GET_SETTING_INT 'HEAD_CONV_INCCOME_AC', @use_head_conv_income_acc OUTPUT

EXEC dbo.GET_DEPT_ACC @dept_no, 'CONV_ACC_19_1A', @acc_19a OUTPUT
EXEC dbo.GET_DEPT_ACC @dept_no, 'CONV_ACC_19_1P', @acc_19p OUTPUT

IF @iso_d = 'GEL'
     SET @acc_906_cur = @acc_906_gel
ELSE SET @acc_906_cur = @acc_906_val

DECLARE 
	@acc_id_d int,
	@acc_id_c int,
	@acc_str varchar(200)

SET @acc_id_d = dbo.acc_get_acc_id(@head_branch_id, @acc_906_cur, @iso_d)

IF @acc_id_d IS NULL
BEGIN
	SET @acc_str = 'Account ' + CONVERT(varchar(20), @head_branch_id) + '/' + CONVERT(varchar(34), @acc_906_cur) + '/' + @iso_d + ' not found'
	RAISERROR (@acc_str, 16, 1)
	RETURN 1
END

IF @iso_c = 'GEL'
     SET @acc_906_cur = @acc_906_gel
ELSE SET @acc_906_cur = @acc_906_val

SET @acc_id_c = dbo.acc_get_acc_id(@head_branch_id, @acc_906_cur, @iso_c)

IF @acc_id_c IS NULL
BEGIN
	SET @acc_str = 'Account ' + CONVERT(varchar(20), @head_branch_id) + '/' + CONVERT(varchar(34), @acc_906_cur) + '/' + @iso_c + ' not found'
	RAISERROR (@acc_str, 16, 1)
	RETURN 1
END


DECLARE
    @op_code1 TOPCODE,
    @op_code2 TOPCODE,
	@cashier int

SET @cashier = NULL

IF @is_kassa = 0
BEGIN
    SET @op_code1 = @op_code
    SET @op_code2 = @op_code
    SET @doc_type1 = ISNULL(@doc_type1, 20)
    SET @doc_type2 = ISNULL(@doc_type2, 14)
END
ELSE
BEGIN
    IF @iso_d <> 'GEL'
       SET @op_code1 = '22'
    ELSE 
    SET @op_code1 = '08'
    IF @iso_c <> 'GEL'
       SET @op_code2 = '63'
    ELSE 
        SET @op_code2 = '45'
    SET @doc_type1 = ISNULL(@doc_type1, 122)
    SET @doc_type2 = ISNULL(@doc_type2, 132)

    SET @doc_type1 = 122
    SET @doc_type2 = 132

	IF @rec_state >= 10
	BEGIN
		IF @rec_state < 20 -- ყვითელია
		BEGIN
			IF EXISTS(SELECT * FROM dbo.USERS (NOLOCK) WHERE [USER_ID] = @user_id AND (IS_OPERATOR_CASHIER = 1 OR IS_CASHIER = 1))
				SET @cashier = @user_id
		END
		ELSE
			SET @cashier = @user_id
	END
END

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

IF @debit_iso <> @iso_d OR @credit_iso <> @iso_c
BEGIN
	IF @lat = 0 
		RAISERROR ('<ERR>ÌÉÈÉÈÄÁÖËÉ ÅÀËÖÔÀ ÀÒ ÄÌÈáÅÄÅÀ ÀÍÂÀÒÉÛÄÁÉÓ ÅÀËÖÔÀÓ</ERR>',16,1)
	ELSE RAISERROR ('<ERR>Supplied currency differs from accounts''s currency</ERR>',16,1)
	RETURN (301)
END

DECLARE 
    @rate_diff_type tinyint
SET @rate_diff_type = 0

SELECT @rate_diff_type = ISNULL(C.RATE_DIFF_TYPE, 0)
FROM dbo.CLIENTS C (NOLOCK)
  INNER JOIN ACCOUNTS A (NOLOCK) ON A.CLIENT_NO = C.CLIENT_NO
WHERE A.ACC_ID = @debit_id

DECLARE @old_amount money
SET @old_amount = null

IF @rate_diff_type = 1
BEGIN
  IF @tariff_kind = 0
  BEGIN
    SET @old_amount = @amount_d
    EXEC dbo.GET_CROSS_AMOUNT  @iso_c,  @iso_d, @amount_c, @doc_date, @amount_d OUTPUT
  END
  ELSE
  BEGIN
    SET @old_amount = @amount_c
    EXEC dbo.GET_CROSS_AMOUNT  @iso_d,  @iso_c, @amount_d, @doc_date, @amount_c OUTPUT
  END
END

IF @channel_id = 50 --  Call center
BEGIN
	EXEC @r = dbo.call_center_check_fx_limits @iso_d, @iso_c, @debit_id, @credit_id, @amount_d, @amount_c, @doc_date, @rec_state OUTPUT
	IF @r <> 0 OR @@ERROR <> 0
		RETURN (901)
END

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
    BEGIN TRAN
    SET @internal_transaction = 1
END


EXEC @r = dbo._INTERNAL_ADD_DOC        -- SELL
    @rec_id = @rec_id_1 OUTPUT,            
    @owner = @owner,
    @doc_type = @doc_type1,
    @doc_date = @doc_date,
    @debit_id = @debit_id,
    @credit_id = @acc_id_d,
    @iso = @iso_d,
    @amount = @amount_d,
    @rec_state = @rec_state,
    @descrip = @descrip1,
    @op_code = @op_code1,
    @parent_rec_id = @par_rec_id,
    @doc_num = @doc_num,
    @dept_no = @dept_no,
    @account_extra = @account_extra,
    @bnk_cli_id = @bnk_cli_id,
    @prod_id = @prod_id,
    @foreign_id = @foreign_id,
    @channel_id = @channel_id,
	@is_suspicious = @is_suspicious,
	@cashier = @cashier,
	@relation_id = @relation_id,
	@flags = @flags

IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

INSERT INTO dbo.DOC_DETAILS_CONV WITH (ROWLOCK) (DOC_REC_ID, RATE_ITEMS, RATE_AMOUNT, RATE_REVERSE, RATE_FLAGS, LAT_DESCRIP, TARIFF_KIND, CLIENT_NO, RATE_CLIENT_NO, AMOUNT3)
VALUES (@rec_id_1, @rate_items, @rate_amount, @rate_reverse, @rate_flags, @lat_descrip, @tariff_kind, @client_no, @rate_client_no, @old_amount)
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 2 END

IF @is_kassa <> 0
BEGIN
    INSERT INTO dbo.DOC_DETAILS_PASSPORTS WITH (ROWLOCK) (DOC_REC_ID,FIRST_NAME,LAST_NAME,FATHERS_NAME,BIRTH_DATE,BIRTH_PLACE,ADDRESS_JUR,ADDRESS_LAT,COUNTRY,PASSPORT_TYPE_ID,PASSPORT,PERSONAL_ID,REG_ORGAN,PASSPORT_ISSUE_DT,PASSPORT_END_DATE)
    VALUES (@rec_id_1,@first_name,@last_name,@fathers_name,@birth_date,@birth_place,@address_jur,@address_lat,@country,@passport_type_id,@passport,@personal_id,@reg_organ,@passport_issue_dt,@passport_end_date)
    IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 3 END
END

INSERT INTO dbo.DOC_CHANGES WITH (ROWLOCK) (DOC_REC_ID,[USER_ID],DESCRIP) 
VALUES (@rec_id_1, @user_id, 'ÓÀÁÖÈÉÓ ÃÀÌÀÔÄÁÀ' + CASE WHEN @user_id = 8 THEN ' (ÁÀÍÊ-ÊËÉÄÍÔÉÈ)' ELSE '' END) /* bank client = 8*/
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 99 END

IF @par_rec_id = -1
  SET @par_rec_id = @rec_id_1

EXEC @r = dbo._INTERNAL_ADD_DOC        -- BUY
    @rec_id = @rec_id_2 OUTPUT,            
    @owner = @owner,
    @doc_type = @doc_type2,
    @doc_date = @doc_date,
    @debit_id = @acc_id_c,
    @credit_id = @credit_id,
    @iso = @iso_c,
    @amount = @amount_c,
    @rec_state = @rec_state,
    @descrip = @descrip2,
    @op_code = @op_code2,
    @parent_rec_id = @par_rec_id,
    @doc_num = @doc_num,
    @dept_no = @dept_no,
    @account_extra = @account_extra,
    @bnk_cli_id = @bnk_cli_id,
    @prod_id = @prod_id,
    @foreign_id = @foreign_id,
    @channel_id = @channel_id,
	@is_suspicious = @is_suspicious,
	@cashier = @cashier,
	@relation_id = @relation_id,
	@flags = @flags
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 5 END

IF @is_kassa <> 0
BEGIN
	INSERT INTO dbo.DOC_DETAILS_PASSPORTS WITH (ROWLOCK) (DOC_REC_ID,FIRST_NAME,LAST_NAME,FATHERS_NAME,BIRTH_DATE,BIRTH_PLACE,ADDRESS_JUR,ADDRESS_LAT,COUNTRY,PASSPORT_TYPE_ID,PASSPORT,PERSONAL_ID,REG_ORGAN,PASSPORT_ISSUE_DT,PASSPORT_END_DATE)
    VALUES (@rec_id_2,@first_name,@last_name,@fathers_name,@birth_date,@birth_place,@address_jur,@address_lat,@country,@passport_type_id,@passport,@personal_id,@reg_organ,@passport_issue_dt,@passport_end_date)
    IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 6 END
END

INSERT INTO dbo.DOC_CHANGES WITH (ROWLOCK) (DOC_REC_ID,[USER_ID],DESCRIP) 
VALUES (@rec_id_2, @user_id, 'ÓÀÁÖÈÉÓ ÃÀÌÀÔÄÁÀ' + CASE WHEN @user_id = 8 THEN ' (ÁÀÍÊ-ÊËÉÄÍÔÉÈ)' ELSE '' END) /* bank client = 8*/
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 99 END

--EXEC @r = dbo.ON_USER_CHECK_DOC @rec_id_1, @user_id, @lat
--IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 8 END

IF @add_tariff <> 0 AND @is_kassa = 0
BEGIN
	DECLARE 
		@tar_kind smallint,
		@tariff_rec_id int,
		@fee money,
		@_doc_type smallint,
		@_debit_id int,
		@_credit_id int,
		@_iso char(3),
		@_amount money,
		@_amount2 money,
		@_op_code varchar(5)

	SET @tar_kind = CASE WHEN @tariff_kind = 0 THEN 1 ELSE 2 END
	SET @_doc_type = CASE WHEN @tariff_kind = 0 THEN @doc_type1 ELSE @doc_type2 END

	SET @_debit_id = CASE WHEN @tariff_kind = 0 THEN @debit_id ELSE @credit_id END
	SET @_credit_id = CASE WHEN @tariff_kind = 0 THEN @credit_id ELSE @debit_id END
	SET @_iso = CASE WHEN @tariff_kind = 0 THEN @iso_d ELSE @iso_c END
	SET @_amount = CASE WHEN @tariff_kind = 0 THEN @amount_d ELSE @amount_c END
	SET @_amount2 = CASE WHEN @tariff_kind = 0 THEN @amount_c ELSE @amount_d END
	SET @_op_code = CASE WHEN @tariff_kind = 0 THEN @op_code1 ELSE @op_code2 END

	EXEC @r = dbo.add_tariff_doc
		@doc_rec_id = @rec_id_1, 
		@tar_kind = @tar_kind,			-- 0 - ჩვეულებრივი საბუთი, 1 - კონვერტაცია. ტარიფის აღება 1–ი საბუთიდან , 2 – კონვერტაცია. ტარიფის აღება 2–ე საბუთიდან 
		@fee_rec_id = @tariff_rec_id OUTPUT,	-- აბრუნებს დამატებული საბუთის REC_ID–ს
		@fee_amount = @fee OUTPUT,		-- აბრუნებს დამატებული საბუთის თანხას (ტარიფის თანხას)

		@user_id = @user_id,			-- ვინ ამატებს საბუთს
		@owner = @owner,				-- პატრონი (გაჩუმებით = @user_id)
		@dept_no = @dept_no,			-- ფილიალისა და განყოფილების №

		@rec_state = @rec_state,		-- სტატუსი

		@doc_type = @_doc_type,			-- საბუთის ტიპი
		@doc_date = @doc_date,			-- ტრანზაქციის თარიღი

		@debit_id = @_debit_id,			-- დებეტის ანგარიში
		@credit_id = @_credit_id,		-- კრედიტის ანგარიში
		@iso = @_iso,					-- ვალუტის კოდი
		@amount = @_amount,				-- თანხა
		@amount2 = @_amount2,				-- თანხა
		@cash_amount = $0.00,			-- სალაროს დასაბეგრი თანხა
		@op_code = @_op_code,			-- ოპერაციის კოდი
		@doc_num = @doc_num,			-- საბუთის ნომერი ან კოდი

		@account_extra = @account_extra,	-- დამატებითი ანგარიშის მისათითებელი ველი
		@prod_id = @prod_id,			-- პროდუქტის ნომერი, რომელიც ამატებს ამ საბუთს
		@foreign_id = @foreign_id,		-- დამატებითი გარე №
		@channel_id = @channel_id,		-- არხი, რომლითაც ემატება ეს საბუთი
		@relation_id = @relation_id,
	
		@cashier = @cashier,
		@receiver_bank_code = null,
		@det_of_charg = null,
		@rate_flags = @rate_flags,

		@info = @info ,					-- რეალურად გატარდეს, თუ მხოლოდ ინფორმაციაა
		@lat = @lat						-- გამოიტანოს თუ არა შეცდომები ინგლისურად

	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 9 END
END

DECLARE 
    @delta money,
    @_debit TACCOUNT,
    @_credit TACCOUNT,
    @amount_equ_d money,
    @amount_equ_c money,
	@branch_id_d int,
	@branch_id_c int

SET @amount_equ_d = dbo.get_equ (@amount_d, @iso_d, @doc_date)
SET @amount_equ_c = dbo.get_equ (@amount_c, @iso_c, @doc_date)

IF @amount_equ_d > @amount_equ_c
  SELECT @delta = @amount_equ_d - @amount_equ_c, 
		@branch_id_d = @head_branch_id, 
		@_debit = @acc_906_gel, 
		@branch_id_c = CASE WHEN @use_head_conv_income_acc = 1 THEN @head_branch_id ELSE @branch_id END, 
		@_credit = @acc_19p
ELSE
IF @amount_equ_d < @amount_equ_c
  SELECT @delta = @amount_equ_c - @amount_equ_d, 
		@branch_id_d = CASE WHEN @use_head_conv_income_acc = 1 THEN @head_branch_id ELSE @branch_id END, 
		@_debit = @acc_19a, 
		@branch_id_c = @head_branch_id, 
		@_credit = @acc_906_gel
ELSE
  SET @delta = $0.0000

SET @delta = ROUND(@delta, 2)

DECLARE @rec_id_others int
    
IF @delta <> $0.0000 
BEGIN
	SET @acc_id_d = dbo.acc_get_acc_id(@branch_id_d, @_debit, 'GEL')

	IF @acc_id_d IS NULL
	BEGIN
		SET @acc_str = 'Account ' + CONVERT(varchar(20), @branch_id_d) + '/' + ISNULL(CONVERT(varchar(34), @_debit), 'NULL') + '/GEL not found'
		RAISERROR (@acc_str, 16, 1)
		RETURN 1
	END

    SET @acc_id_c = dbo.acc_get_acc_id(@branch_id_c, @_credit, 'GEL')

	IF @acc_id_c IS NULL
	BEGIN
		SET @acc_str = 'Account ' + CONVERT(varchar(20), @branch_id_c) + '/' + ISNULL(CONVERT(varchar(34), @_credit),'NULL') + '/GEL not found'
		RAISERROR (@acc_str, 16, 1)
		RETURN 1
	END

    EXEC @r = dbo._INTERNAL_ADD_DOC
        @rec_id = @rec_id_others OUTPUT,            
        @owner = @owner,
        @doc_type = 16,
        @doc_date = @doc_date,
        @debit_id = @acc_id_d,
        @credit_id = @acc_id_c,
        @iso = 'GEL',
        @amount = @delta,
        @rec_state = @rec_state,
        @descrip = 'ÊÏÍÅÄÒÓÉÀ (ÓÀÊÖÒÓÏ ÓáÅÀÏÁÀ)',
        @op_code = '*CVR*',
        @parent_rec_id = @par_rec_id,
        @doc_num = @doc_num,
        @dept_no = @dept_no,
        @account_extra = @account_extra,
        @bnk_cli_id = @bnk_cli_id,
        @prod_id = @prod_id,
        @foreign_id = @foreign_id,
        @channel_id = @channel_id,
		@is_suspicious = @is_suspicious,
		@relation_id = @relation_id,
		@flags = @flags
    IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 11 END
END

IF @check_saldo <> 0
BEGIN
    IF @debit_act_pas <> 2 /* not Active account */
    BEGIN
        EXEC @r = dbo.CHECK_SALDO @debit_id, @doc_date, @op_code1, @doc_type1, @rec_id_1, @lat
        IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 53 END
    END

    IF @credit_act_pas = 2 /* Active account */
    BEGIN
        EXEC @r = dbo.CHECK_SALDO @credit_id, @doc_date, @op_code2, @doc_type2, @rec_id_2, @lat
        IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 53 END
    END
END

IF @rec_state >= 10
BEGIN
	EXEC @r = dbo.ON_USER_BEFORE_AUTHORIZE_DOC @rec_id_1, @user_id, @owner, @rec_state, 0,
		@par_rec_id,	@dept_no, @doc_type1, @doc_date, null, @debit_id, @credit_id, @iso_d, @amount_d, $0.00,
		@op_code, @doc_num,	@account_extra, @prod_id, @foreign_id, @channel_id,	@relation_id, @cashier, @info, @lat
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

	EXEC @r = dbo.ON_USER_AFTER_AUTHORIZE_DOC @rec_id_1, @user_id, @rec_state, 0
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

	EXEC @r = dbo.ON_USER_BEFORE_AUTHORIZE_DOC @rec_id_2, @user_id, @owner, @rec_state, 0,
		@par_rec_id,	@dept_no, @doc_type2, @doc_date, null, @debit_id, @credit_id, @iso_c, @amount_c, $0.00,
		@op_code, @doc_num,	@account_extra, @prod_id, @foreign_id, @channel_id,	@relation_id, @cashier, @info, @lat
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

	EXEC @r = dbo.ON_USER_AFTER_AUTHORIZE_DOC @rec_id_2, @user_id, @rec_state, 0
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
END

EXEC @r = dbo.ON_USER_AFTER_ADD_CONV_DOC
	@rec_id_1 = @rec_id_1,
	@rec_id_2 = @rec_id_2,
	@user_id = @user_id,
	@owner = @owner,
	@iso_d = @iso_d,
	@iso_c = @iso_c,

	@amount_d = @amount_d,
	@amount_c = @amount_c,
	@debit_id = @debit_id,
	@credit_id = @credit_id,
	@doc_date = @doc_date,
	@op_code = @op_code,
	@doc_num = @doc_num,
	@account_extra = @account_extra,

	@is_kassa = @is_kassa,
  
	@descrip1 = @descrip1,
	@descrip2 = @descrip2,
	@rec_state = @rec_state,
	@bnk_cli_id = @bnk_cli_id,
	@par_rec_id = @par_rec_id,

	@dept_no = @dept_no,
	@prod_id = @prod_id,
	@foreign_id = @foreign_id,
	@channel_id = @channel_id,
	@is_suspicious = @is_suspicious,

	@relation_id = @relation_id,
	@flags = @flags,

	@rate_items = @rate_items,
	@rate_amount = @rate_amount,
	@rate_reverse = @rate_reverse,
	@rate_flags = @rate_flags,
	@tariff_kind = @tariff_kind,
	@lat_descrip = @lat_descrip,

	@client_no = @client_no,
	@rate_client_no = @rate_client_no,

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

	@doc_type1 = @doc_type1,
	@doc_type2 = @doc_type2,

	@check_saldo = @check_saldo,
	@add_tariff = @add_tariff,
	@info = @info,
	@lat = @lat,
	@extra_params = @extra_params
IF @@ERROR <> 0 OR @r <> 0 RETURN 1

IF @internal_transaction=1 AND @@TRANCOUNT>0 
    COMMIT TRAN
RETURN (0)
GO
