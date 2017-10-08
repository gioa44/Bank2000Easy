SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[PLASTIC_CARD_ADD_DOC_FROM_MERCHANT_SLK]
	@user_id int,
	@doc_num int = 0,
	@merchant_id int,
	@card_id varchar(19),
	@date datetime,
	@amount TAMOUNT,
	@fee TAMOUNT,
	@ccy char(3),
	@ref_num varchar(12),
	@auth_code varchar(12),
	@region char(1) = 'L',
	@proc_region char(1) = 'L',
	@proc_merchant_type char(1) = 'A',
	@add_descrip varchar(150),
	@lat bit = 0,
	@output_msg nvarchar(100) OUTPUT
AS

SET NOCOUNT ON

DECLARE
	@rec_id int,
	@recv_bank_code TGEOBANKCODE,
	@recv_acc_n TACCOUNT,
	@recv_acc_v TACCOUNT,
	@recv_acc TACCOUNT,
	@recv_acc_name varchar(50),
	@sender_acc_n TACCOUNT,
	@sender_acc_v TACCOUNT,
	@sender_acc_name varchar(50),
	@sender_acc_n_2 TACCOUNT,
	@sender_acc_v_2 TACCOUNT,
	@sender_acc_name_2 varchar(50),
	@fee_acc_n TACCOUNT,
	@fee_acc_v TACCOUNT,
	@conv_acc_n TACCOUNT,
	@conv_acc_v TACCOUNT,
	@op_code varchar(5),
	@our_bank_code TGEOBANKCODE,
	@our_bank_name varchar(100),
	@recv_bank_name varchar(100),
	@credit TACCOUNT,
	@debit TACCOUNT,
	@debit_c TACCOUNT,
	@is_branch bit,
	@rec_state int,
	@doc_type int,
	@r int,
	@parent_rec_id int,
	@dept_no int,
	@today smalldatetime,
	@descrip varchar(150),
	@descrip_1 varchar(150),
	@is_convert bit,
	@use_cursor bit,
	@merchant_type tinyint,
	@rate_amount DECIMAL(12,4),
	@min_amount TAMOUNT,
	@non_reduce_amount TAMOUNT,
	@tariff_amount TAMOUNT,
	@convert_amount TAMOUNT,
	@rec_id_2 int,
	@amount_c TAMOUNT,
	@fee_min_amount TAMOUNT,
	@fee_percent TAMOUNT,
	@iso TISO,
	@old_iso TISO,
	@descrip1 varchar(50),
	@card_category char(3),
	@client_category char(3),
	@card_type tinyint,
	@acc_income TACCOUNT,
	@acc_outcome TACCOUNT,
	@acc_outcome_v TACCOUNT,
	@acc_ofb_d TACCOUNT,
	@acc_ofb_c TACCOUNT,
	@account_extra TACCOUNT

SET @acc_ofb_d = 0
SET @acc_ofb_c = 1
SET @doc_type = 12

SET @acc_income  = 6409200049
SET @acc_outcome = 8409530029
SET @acc_outcome_v = 8419530029

SET @today = convert(smalldatetime,floor(convert(real,getdate())))

SELECT @dept_no=DEPT_NO
FROM USERS
WHERE [USER_ID] = @user_id

IF EXISTS(SELECT * FROM dbo.PLASTIC_CARDS WHERE CARD_ID = @card_id)
BEGIN
	PRINT 'Is Our Card'
	RETURN 0
END

PRINT 'Merchant type is: ' + @proc_merchant_type

IF @proc_merchant_type = 'A'
	SET @merchant_type = 1
ELSE
IF @proc_merchant_type = 'P'
	SET @merchant_type = 2
ELSE
IF @proc_merchant_type = 'N'
	SET @merchant_type = 3

--'A' - ATM
--'P' - POS
--'N' - IMPRINTER

-- ჩვენი ბარათის და მერჩჩანტის ფაილის შემთხვევაში არ ვაკეთებთ გატარებას, რადგან ეს ინფორმაციე ემატება LO-ფაილიდან

SET @iso = @ccy

-- თუ არაა ჩვენი მერჩანტი მაშინ იცვლება მერჩანტის ID

IF @tariff_amount > $0.00
	SET @parent_rec_id = -1
ELSE
	SET @parent_rec_id = 0

-- თუ ბარათზე მიბმული ანგარიში არა ემთხვევა ს.ც-დან მიღებულ ანგარიშს მაშინ უნდა მოხდეს კონვერტაცია ან კონვერტაციები
IF NOT EXISTS(SELECT TOP 1 * FROM dbo.PLASTIC_CARD_MERCHANTS(NOLOCK) WHERE MERCHANT_ID = @merchant_id)
BEGIN
	IF @merchant_type = 1
		SET @merchant_id = 9999999
	ELSE
	IF @merchant_type = 2
		SET @merchant_id = 9999998
	ELSE
		SET @merchant_id = 9999997
END

SELECT	@recv_bank_code = RECV_BANK_CODE, @recv_acc_n = RECV_ACC_N, @recv_acc_v = RECV_ACC_V,
		@recv_acc_name = RECV_ACC_NAME, @op_code = OP_CODE, @merchant_type = MERCHANT_TYPE,
		@fee_acc_n = FEE_ACC_N, @fee_acc_v = FEE_ACC_V, @conv_acc_n = CONV_ACC_N, @conv_acc_v = CONV_ACC_V,
		@sender_acc_n = SENDER_ACC_N, @sender_acc_v = SENDER_ACC_V, @sender_acc_name = SENDER_ACC_NAME,
		@sender_acc_n_2 = SENDER_ACC_N_2, @sender_acc_v_2 = SENDER_ACC_V_2, @sender_acc_name_2 = SENDER_ACC_NAME_2,
		@fee_min_amount = FEE_MIN_AMOUNT, @fee_percent = FEE_PERCENT
FROM	dbo.PLASTIC_CARD_MERCHANTS
WHERE	MERCHANT_ID = @merchant_id

IF @proc_region = 'L'--მერჩანტის ფაილი
BEGIN

	IF @fee > 0
	BEGIN
		SET @tariff_amount = @fee
		SET @parent_rec_id = -1
	END
END

--არც ბარათი და არც მერჩანტი არაა ბანკის

IF @iso = 'GEL'
BEGIN
	SET @recv_acc = @recv_acc_n
	IF (@proc_region = 'E' OR @proc_region = 'M' OR @proc_region = 'D' OR @proc_region = 'W')
		SET @debit = @sender_acc_n_2
	IF (@proc_region = 'L')
		SET @debit = @sender_acc_n
END
ELSE
BEGIN
	SET @recv_acc = @recv_acc_v
	IF (@proc_region = 'E' OR @proc_region = 'M') OR (@region = 'E' AND @proc_region = 'D')
		SET @debit = @sender_acc_v_2
	IF (@proc_region = 'L' OR @proc_region = 'D')
		SET @debit = @sender_acc_v
END

EXEC dbo.GET_SETTING_INT 'OUR_BANK_CODE', @our_bank_code OUTPUT
EXEC GET_SETTING_STR 'OUR_BANK_NAME', @our_bank_name OUTPUT

--მიმღები ბანკი არ მოიძებნა
EXEC @r = dbo.BCC_CHECK_RECV_BANK_GEO @recv_bank_code, @recv_bank_name OUTPUT, @credit OUTPUT, @is_branch OUTPUT, 'GEL', @lat
IF @@ERROR <> 0 OR @r <> 0 RETURN 8

IF @merchant_type = 1
	SET @descrip = 'ÈÀÍáÉÓ ÌÏáÓÍÀ: '
ELSE
	SET @descrip = 'POS-ÉÓ ÏÐÄÒÀÝÉÀ: '

IF @merchant_id IN (828012, 828277, 827089)
	SET @descrip = 'ÈÀÍáÉÓ ÌÏáÓÍÀ: '

SET @descrip = @descrip + CONVERT(VARCHAR(20), @date, 20) + ' ÀÅÔ. ÊÏÃÉ: ' + @auth_code
IF ISNULL(@add_descrip, '') <> ''
	SET @descrip = @descrip + ' ' + @add_descrip

SET @rec_state = 0

IF @recv_bank_code = @our_bank_code /* internal transfer */
BEGIN
	SET @doc_type = 98
	SET @credit = convert(decimal(15,0),@recv_acc)
	SET @recv_bank_name = @our_bank_name
END
ELSE
BEGIN
	SET @doc_type = 102

	IF @is_branch <> 0
	BEGIN
		SET @doc_type = 101
	END
END

DECLARE 
	@internal_transaction bit

SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

	IF @proc_region = 'E' OR @proc_region = 'M' OR @proc_region = 'D' OR @proc_region = 'W'
	BEGIN
		SET @tariff_amount = 0
		SET @parent_rec_id = 0
	END

	IF ((@region = 'E' AND @proc_region = 'D') OR @proc_region = 'E' OR @proc_region = 'M' OR @proc_region = 'W') AND @ccy = 'GEL'
	BEGIN
	-- კონვერტაცია
		
		SET @rate_amount = dbo.get_cross_rate('USD', 'GEL', @today)

		SET @amount_c = @amount / @rate_amount

		SET @descrip1 = 'ÊÏÍÅÄÒÓÉÀ (ÊÒÏÓ-ÊÖÒÓÉ: 1 USD = ' + CONVERT(VARCHAR(15), @rate_amount) + ' GEL)'

		EXEC @r=ADD_CONV_DOC @rec_id OUTPUT,@rec_id_2 OUTPUT,@user_id=@user_id,@dept_no=@dept_no,@doc_num=@doc_num
		,@op_code=@op_code,@doc_date=@today,@iso_d='USD',@iso_c=@ccy,@amount_d=@amount_c,@amount_c=@amount
		,@descrip1=@descrip,@descrip2=@descrip1
		,@debit=@sender_acc_v_2,@credit=@recv_acc_n,@rate_items=1,@rate_amount=@rate_amount,@rate_reverse=0,@rate_flags=21
		,@lat_descrip=0,@tariff_kind=0,@info=0
		,@is_kassa=0,@rec_state=0,@add_tariff=0,@check_saldo=0
	END
	ELSE
	BEGIN

		EXEC @r = dbo.ADD_DOC
			@rec_id OUTPUT,
			@user_id=@user_id,@dept_no=@dept_no,@doc_date=@today,@doc_date_in_doc=@today,
			@iso=@ccy,@amount=@amount,@doc_num=@doc_num,@op_code=@op_code,
			@sender_acc=@debit,@sender_acc_name=@sender_acc_name,@debit=@debit,
			@receiver_bank_code=@recv_bank_code, @receiver_acc=@recv_acc, @receiver_acc_name=@recv_acc_name,
			@rec_state=@rec_state,@descrip=@descrip,
			@parent_rec_id=@parent_rec_id,@add_tariff=0,
			@sender_bank_code=@our_bank_code,@sender_bank_name=@our_bank_name,
			@doc_type=@doc_type, @credit=@credit, @receiver_bank_name=@recv_bank_name,@check_saldo=0

		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

		SET @parent_rec_id = @rec_id

		IF @tariff_amount > $0.000
		BEGIN
			SET @recv_acc = CASE WHEN @ccy = 'GEL' THEN @fee_acc_n ELSE @fee_acc_v END

			SET @account_extra = null

			IF dbo.acc_is_incasso(@recv_acc_n, @ccy) = 1
			BEGIN
				SET @output_msg = CONVERT(varchar(15), @recv_acc_n) + '/' + @ccy + N' ანგარიშს ადევს ინკასო'
				SET @account_extra = @recv_acc_n
				SET @debit = @acc_ofb_d
				SET @recv_acc = @acc_ofb_c
				SET @doc_type = 200
			END

			EXEC @r = dbo.ADD_DOC
				@rec_id OUTPUT,
				@user_id=@user_id,@dept_no=@dept_no,@doc_date=@today,
				@iso=@ccy,@amount=@tariff_amount,@doc_num=@doc_num,@op_code=@op_code,
				@debit=@debit,@credit=@recv_acc,
				@rec_state=0,
				@descrip='ÂÀÍÀÙÃÄÁÉÓ ÓÀÊÏÌÉÓÉÏ',@owner=@user_id,
				@doc_type=@doc_type,@lat=@lat,@parent_rec_id=@rec_id,@add_tariff=0,@check_saldo=0,@account_extra=@account_extra

			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
		END
	

	END

IF @merchant_id IN (9083007, 9083015, 9083023, 9086000, 9289000, 9084013, 9084005, 9084021, 9084047, 9084039, 9086018, 9089004, 9083031, 9180019, 
				    9089012, 9382003, 9382011, 9287004, 9083122, 9083072, 9083114, 9083106, 9083098, 9083080, 9083056, 9083064, 9083049, 9289018, 
					9086026)
BEGIN
	IF @proc_region = 'L' AND @ccy = 'GEL'
	BEGIN
		SET @tariff_amount = dbo.plastic_card_get_tariff_SLK(@card_type, @merchant_id, @amount, 'GEL', @today)
		SET @recv_acc = CASE WHEN @ccy = 'GEL' THEN @fee_acc_n ELSE @fee_acc_v END
		SET @descrip_1 = @descrip + '  ÓÀÊÏÌÉÓÉÏ'
		IF @tariff_amount > 0
		BEGIN

			SET @account_extra = null

			IF dbo.acc_is_incasso(@recv_acc_n, @ccy) = 1
			BEGIN
				SET @output_msg = CONVERT(varchar(15), @recv_acc_n) + '/' + @ccy + N' ანგარიშს ადევს ინკასო'
				SET @account_extra = @recv_acc_n
				SET @recv_acc_n = @acc_ofb_d
				SET @acc_income = @acc_ofb_c
				SET @doc_type = 200
			END

			EXEC @r = dbo.ADD_DOC
				@rec_id OUTPUT,
				@user_id=@user_id,@dept_no=@dept_no,@doc_date=@today,
				@iso='GEL',@amount=@tariff_amount,@doc_num=@doc_num,@op_code=@op_code,
				@debit=@recv_acc_n,@credit=@acc_income,
				@rec_state=0,
				@descrip=@descrip_1,@owner=@user_id,
				@doc_type=@doc_type,@lat=@lat,@parent_rec_id=0,@add_tariff=0,@check_saldo=0,@account_extra=@account_extra

			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
		END
	END
	ELSE
	IF @region <> 'E' AND @proc_region = 'D' AND @ccy = 'GEL'
	BEGIN
		SET @tariff_amount = (@amount * 2.5) / 100
		SET @descrip_1 = @descrip + '  ÓÀÊÏÌÉÓÉÏ'

		SET @account_extra = null

		IF dbo.acc_is_incasso(@recv_acc_n, @ccy) = 1
		BEGIN
			SET @output_msg = CONVERT(varchar(15), @recv_acc_n) + '/' + @ccy + N' ანგარიშს ადევს ინკასო'
			SET @account_extra = @recv_acc_n
			SET @recv_acc_n = @acc_ofb_d
			SET @acc_income = @acc_ofb_c
			SET @doc_type = 200
		END

		EXEC @r = dbo.ADD_DOC
			@rec_id OUTPUT,
			@user_id=@user_id,@dept_no=@dept_no,@doc_date=@today,
			@iso='GEL',@amount=@tariff_amount,@doc_num=@doc_num,@op_code=@op_code,
			@debit=@recv_acc_n,@credit=@acc_income,
			@rec_state=0,
			@descrip=@descrip_1,@owner=@user_id,
			@doc_type=@doc_type,@lat=@lat,@parent_rec_id=-1,@add_tariff=0,@check_saldo=0,@account_extra=@account_extra

		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

		SET @tariff_amount = (@amount * 1.8) / 100
		SET @descrip_1 = @descrip + '  áÀÒãÉ'

		EXEC @r = dbo.ADD_DOC
			@rec_id OUTPUT,
			@user_id=@user_id,@dept_no=@dept_no,@doc_date=@today,
			@iso='GEL',@amount=@tariff_amount,@doc_num=@doc_num,@op_code=@op_code,
			@debit=@acc_outcome,@credit=@sender_acc_n_2,
			@rec_state=0,
			@descrip=@descrip_1,@owner=@user_id,
			@doc_type=12,@lat=@lat,@parent_rec_id=@rec_id,@add_tariff=0,@check_saldo=0

		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

	END
	ELSE
	IF (@proc_region = 'E' OR @proc_region = 'M' OR @proc_region = 'W') AND @ccy <> 'GEL'
	BEGIN
		SET @tariff_amount = (@amount * dbo.get_cross_rate('USD', 'GEL', @today) * 2.5) / 100
		SET @descrip_1 = @descrip + '  ÓÀÊÏÌÉÓÉÏ'

		SET @account_extra = null

		IF dbo.acc_is_incasso(@recv_acc_n, @ccy) = 1
		BEGIN
			SET @output_msg = CONVERT(varchar(15), @recv_acc_n) + '/' + @ccy + N' ანგარიშს ადევს ინკასო'
			SET @account_extra = @recv_acc_n
			SET @recv_acc_n = @acc_ofb_d
			SET @acc_income = @acc_ofb_c
			SET @doc_type = 200
		END

		EXEC @r = dbo.ADD_DOC
			@rec_id OUTPUT,
			@user_id=@user_id,@dept_no=@dept_no,@doc_date=@today,
			@iso='GEL',@amount=@tariff_amount,@doc_num=@doc_num,@op_code=@op_code,
			@debit=@recv_acc_n,@credit=@acc_income,
			@rec_state=0,
			@descrip=@descrip_1,@owner=@user_id,
			@doc_type=@doc_type,@lat=@lat,@parent_rec_id=-1,@add_tariff=0,@check_saldo=0,@account_extra=@account_extra

		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

		SET @tariff_amount = @amount * 1.8 / 100
		SET @descrip_1 = @descrip + '  áÀÒãÉ'

		EXEC @r = dbo.ADD_DOC
			@rec_id OUTPUT,
			@user_id=@user_id,@dept_no=@dept_no,@doc_date=@today,
			@iso='USD',@amount=@tariff_amount,@doc_num=@doc_num,@op_code=@op_code,
			@debit=@acc_outcome_v,@credit=@sender_acc_v_2,
			@rec_state=0,
			@descrip=@descrip_1,@owner=@user_id,
			@doc_type=12,@lat=@lat,@parent_rec_id=@rec_id,@add_tariff=0,@check_saldo=0

		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

	END
	ELSE
	BEGIN
		SET @tariff_amount = (@amount * 2.5) / 100
		SET @descrip_1 = @descrip + '  ÓÀÊÏÌÉÓÉÏ'

		SET @account_extra = null

		IF dbo.acc_is_incasso(@recv_acc_n, @ccy) = 1
		BEGIN
			SET @output_msg = CONVERT(varchar(15), @recv_acc_n) + '/' + @ccy + N' ანგარიშს ადევს ინკასო'
			SET @account_extra = @recv_acc_n
			SET @recv_acc_n = @acc_ofb_d
			SET @acc_income = @acc_ofb_c
			SET @doc_type = 200
		END

		EXEC @r = dbo.ADD_DOC
			@rec_id OUTPUT,
			@user_id=@user_id,@dept_no=@dept_no,@doc_date=@today,
			@iso='GEL',@amount=@tariff_amount,@doc_num=@doc_num,@op_code=@op_code,
			@debit=@recv_acc_n,@credit=@acc_income,
			@rec_state=0,
			@descrip=@descrip_1,@owner=@user_id,
			@doc_type=@doc_type,@lat=@lat,@parent_rec_id=-1,@add_tariff=0,@check_saldo=0,@account_extra=@account_extra

		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

		SET @tariff_amount = (@amount / dbo.get_cross_rate('USD', 'GEL', @today) * 1.8) / 100
		SET @descrip_1 = @descrip + '  áÀÒãÉ'

		EXEC @r = dbo.ADD_DOC
			@rec_id OUTPUT,
			@user_id=@user_id,@dept_no=@dept_no,@doc_date=@today,
			@iso='USD',@amount=@tariff_amount,@doc_num=@doc_num,@op_code=@op_code,
			@debit=@acc_outcome_v,@credit=@sender_acc_v_2,
			@rec_state=0,
			@descrip=@descrip_1,@owner=@user_id,
			@doc_type=12,@lat=@lat,@parent_rec_id=@rec_id,@add_tariff=0,@check_saldo=0

		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

	END
END
	COMMIT TRAN
	RETURN 0
GO
