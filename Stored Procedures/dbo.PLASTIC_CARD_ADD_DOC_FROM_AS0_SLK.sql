SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[PLASTIC_CARD_ADD_DOC_FROM_AS0_SLK]
	@user_id int,
	@doc_num int = 0,
	@merchant_id int,
	@card_id varchar(19),
	@account varchar(20),		-- ანგარიში, რომლიდანაც უნდა მოიხსნას თანხა
	@account_ccy char(3),		-- ანგარიშის ვალუტა
	@tran_datetime datetime,	-- ტრანზაქციის თარიღი და დრო
	@tran_amount TAMOUNT,		-- ტრანზაქციის თანხა, რომელიც აიღო ხელზე კლიენტმა
	@tran_ccy char(3),			-- ტრანზაქციის ვალუტა
	@account_amount TAMOUNT,	-- თანხა, რაც უნდა ჩამოიàრას კლიენტის ანგარიშშიდან, ÓÀÊÏÌÉÓÉÏÄÁÉÓ ÂÀÒÄÛÄ
	@amount TAMOUNT,			-- თანხა, რაც უნდა ჩამოიàრას კლიენტის ანგარიშშიდან
	@amount_net TAMOUNT,		-- თანხა, რაც უნდა ჩამოიàრას კლიენტის ანგარიშშიდან
	@fee TAMOUNT,				-- განაღდების საკომისიო
	@conv_rate decimal(14,7),	-- კონვერტაციის კურსი
	@ref_num varchar(12) ='',
	@auth_code varchar(12),		-- ავტორიზაციის კოდი
	@terminal char(1) = 'A',	-- ტერმინალის ტიპი
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
	@is_our_card bit,
	@is_our_merchant bit,
	@is_convert bit,
	@terminal_type tinyint,
	@min_amount TAMOUNT,
	@non_reduce_amount TAMOUNT,
	@tariff_amount TAMOUNT,
	@convert_amount TAMOUNT,
	@rec_id_2 int,
	@amount_c TAMOUNT,
	@descrip1 varchar(50),
	@card_category char(3),
	@client_category char(3),
	@card_type tinyint,
	@acc_ofb_d TACCOUNT,
	@acc_ofb_c TACCOUNT,
	@account_extra TACCOUNT

SET @acc_ofb_d = 0
SET @acc_ofb_c = 1
SET @doc_type = 12

SET @today = convert(smalldatetime,floor(convert(real,getdate())))

SELECT @dept_no=DEPT_NO
FROM USERS
WHERE [USER_ID] = @user_id

IF EXISTS(SELECT * FROM dbo.PLASTIC_CARDS WHERE CARD_ID = @card_id)
BEGIN
	SET @is_our_card = 1
	PRINT 'Is Our Card'
END
ELSE
BEGIN
	SET @is_our_card = 0
	PRINT 'Is Not Our Card'
	RETURN 5	--არ არის ჩვენი ბარათი
END

PRINT 'Terminal type is: ' + @terminal

IF @terminal = 'A'
	SET @terminal_type = 1
ELSE
IF @terminal = 'P'
	SET @terminal_type = 2
ELSE
IF @terminal = 'N'
	SET @terminal_type = 3

--'A' - ATM
--'P' - POS
--'N' - IMPRINTER

SELECT @card_category = CONDITION_SET, @card_type = CARD_TYPE
FROM dbo.PLASTIC_CARDS
WHERE CARD_ID = @card_id

SET @is_our_merchant = 1 -- ჩვენი მერჩანტი

-- თუ არაა ჩვენი მერჩანტი მაშინ იცვლება მერჩანტის ID
IF NOT EXISTS(SELECT * FROM dbo.PLASTIC_CARD_MERCHANTS WHERE MERCHANT_ID = @merchant_id)
BEGIN
	-- რადგან არ არის ჩვენი მერჩანტი, ანდაგიშები უნდა ავიღოღ სატრანზიტოები, უცხო მერჩანტების
	SET @terminal_type = @terminal_type + 3

	SELECT @merchant_id = MERCHANT_ID
	FROM dbo.PLASTIC_CARD_MERCHANTS
	WHERE MERCHANT_TYPE = @terminal_type
	SET @is_our_merchant = 0
END

SET @tariff_amount = 0.0

IF @is_our_merchant = 1 AND @terminal_type > 1
SET @tariff_amount = dbo.plastic_card_get_tariff_SLK(@card_type, @merchant_id, @amount, 'GEL', @today)

--IF @tariff_amount > $0.00
--	SET @parent_rec_id = -1
--ELSE
	SET @parent_rec_id = 0

-- თუ ტრანზაქციის ვალუტა არ ემთხვევა ანგარიშის ვალუტას, მაშინ უნდა მოხდეს კონვერტაცია
IF @account_ccy = @tran_ccy
	SET @is_convert = 0
ELSE
	SET @is_convert = 1

SELECT	@recv_bank_code = RECV_BANK_CODE, @recv_acc_n = RECV_ACC_N, @recv_acc_v = RECV_ACC_V,
		@recv_acc_name = RECV_ACC_NAME, @op_code = OP_CODE, @terminal_type = MERCHANT_TYPE,
		@fee_acc_n = FEE_ACC_N, @fee_acc_v = FEE_ACC_V, @conv_acc_n = CONV_ACC_N, @conv_acc_v = CONV_ACC_V,
		@sender_acc_n = SENDER_ACC_N, @sender_acc_v = SENDER_ACC_V, @sender_acc_name = SENDER_ACC_NAME,
		@sender_acc_n_2 = SENDER_ACC_N_2, @sender_acc_v_2 = SENDER_ACC_V_2, @sender_acc_name_2 = SENDER_ACC_NAME_2
FROM dbo.PLASTIC_CARD_MERCHANTS
WHERE MERCHANT_ID = @merchant_id


--ჩვენი ბარათის შემთხვევაში დასახელებას ვიღებ ანგარიშებიდან
SELECT @sender_acc_name = DESCRIP
FROM dbo.ACCOUNTS
WHERE ACCOUNT = @account AND ISO = @account_ccy

IF @is_our_merchant = 1
	PRINT 'Our Merchant'
ELSE
	PRINT 'Other Merchant'

IF @is_convert = 1
	PRINT 'Use Convert'
ELSE
	PRINT 'Do Not Use Convert'

-- აქ დაამატე იმ მერჩანტის ნომრები, რომლებიდანაც მხოლოდ თანხის განაღდება ხდება!!
IF @merchant_id IN (828012, 828277, 827089)
	SET @terminal_type = 1

IF @tran_ccy = 'GEL'
	SET @recv_acc = @recv_acc_n
ELSE
	SET @recv_acc = @recv_acc_v

EXEC dbo.GET_SETTING_INT 'OUR_BANK_CODE', @our_bank_code OUTPUT
EXEC GET_SETTING_STR 'OUR_BANK_NAME', @our_bank_name OUTPUT

--მიმღები ბანკი არ მოიძებნა
EXEC @r = dbo.BCC_CHECK_RECV_BANK_GEO @recv_bank_code, @recv_bank_name OUTPUT, @credit OUTPUT, @is_branch OUTPUT, 'GEL', @lat
IF @@ERROR <> 0 OR @r <> 0 RETURN 8

IF @terminal_type = 1 OR @is_our_merchant = 0
	SET @descrip = 'ÈÀÍáÉÓ ÌÏáÓÍÀ: '
ELSE
	SET @descrip = 'POS-ÉÓ ÏÐÄÒÀÝÉÀ: '

SET @descrip = @descrip + CONVERT(VARCHAR(20), @tran_datetime, 20) + ' ÀÅÔ. ÊÏÃÉ: ' + @auth_code
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

-- თუ არის ჩვენი ბარათი და საჭიროა კონვერტაცია
IF @is_convert = 1
BEGIN
-- კონვერტაცია

	--SET	@tran_amount = @account_amount / @conv_rate
	SET @descrip1 = 'ÊÏÍÅÄÒÓÉÀ (ÊÒÏÓ-ÊÖÒÓÉ: 1 ' + @account_ccy + ' = ' + CONVERT(VARCHAR(15), @conv_rate) + ' ' + @tran_ccy + ')'
	SET @recv_acc = CASE WHEN @tran_ccy = 'GEL' THEN @recv_acc_n ELSE @recv_acc_v END

	EXEC @r=ADD_CONV_DOC @rec_id OUTPUT,@rec_id_2 OUTPUT,@user_id=@user_id,@dept_no=@dept_no,@doc_num=@doc_num
		,@op_code=@op_code,@doc_date=@today,@iso_d=@account_ccy,@iso_c=@tran_ccy,@amount_d=@account_amount,@amount_c=@tran_amount
		,@descrip1=@descrip,@descrip2=@descrip1
		,@debit=@account,@credit=@recv_acc, @rate_items=1,@rate_amount=@conv_rate,@rate_reverse=0,@rate_flags=21
		,@lat_descrip=0,@tariff_kind=0,@info=0
		,@is_kassa=0,@rec_state=0,@add_tariff=0,@check_saldo=0

	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

	SET @recv_acc = CASE WHEN @account_ccy = 'GEL' THEN @conv_acc_n ELSE @conv_acc_v END
	SET	@tran_amount = @amount_net - @account_amount
	SET @rec_id = 0

	IF @tariff_amount > $0.004
		EXEC @r = dbo.ADD_DOC
			@rec_id OUTPUT,
			@user_id=@user_id,@dept_no=@dept_no,@doc_date=@today,
			@iso=@account_ccy,@amount=@tran_amount,@doc_num=@doc_num,@op_code=@op_code,
			@debit=@account,@credit=@recv_acc,
			@rec_state=0,
			@descrip='ÊÏÍÅÄÒÔÀÝÉÉÓ ÓÀÊÏÌÉÓÉÏ',@owner=@user_id,
			@doc_type=12,@lat=@lat,@parent_rec_id=@rec_id,@add_tariff=0,@check_saldo=0

	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

END
ELSE
BEGIN
	EXEC @r = dbo.ADD_DOC
		@rec_id OUTPUT,
		@user_id=@user_id,@dept_no=@dept_no,@doc_date=@today,@doc_date_in_doc=@today,
		@iso=@account_ccy,@amount=@amount,@doc_num=@doc_num,@op_code=@op_code,
		@sender_acc=@account,@sender_acc_name=@sender_acc_name,@debit=@account,
		@receiver_bank_code=@recv_bank_code, @receiver_acc=@recv_acc, @receiver_acc_name=@recv_acc_name,
		@rec_state=@rec_state,@descrip=@descrip,
		@parent_rec_id=@parent_rec_id,@add_tariff=0,
		@sender_bank_code=@our_bank_code,@sender_bank_name=@our_bank_name,
		@doc_type=@doc_type, @credit=@credit, @receiver_bank_name=@recv_bank_name,@check_saldo=0

	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

END

SET @rec_id = 0

IF @fee > $0.004
BEGIN
	SET @recv_acc = CASE WHEN @account_ccy = 'GEL' THEN @fee_acc_n ELSE @fee_acc_v END

	IF @is_convert = 1 --AND @is_our_merchant=0
	BEGIN
		SET @recv_acc = CASE WHEN @account_ccy <> 'GEL' THEN @fee_acc_n ELSE @fee_acc_v END
		IF @account_ccy <> 'GEL' AND @tran_ccy <> 'GEL' 
			SET @recv_acc = @fee_acc_v

		SET	@tran_amount = @fee / @conv_rate
		SET @descrip = 'ÂÀÍÀÙÃÄÁÉÓ ÓÀÊÏÌÉÓÉÏ: '
		SET @descrip1 = 'ÊÏÍÅÄÒÓÉÀ (ÊÒÏÓ-ÊÖÒÓÉ: 1 ' + @account_ccy + ' = ' + CONVERT(VARCHAR(15), @conv_rate) + ' ' + @tran_ccy + ')'

		EXEC @r=ADD_CONV_DOC @rec_id OUTPUT,@rec_id_2 OUTPUT,@user_id=@user_id,@dept_no=@dept_no,@doc_num=@doc_num
			,@op_code=@op_code,@doc_date=@today,@iso_d=@account_ccy,@iso_c=@tran_ccy,@amount_d=@fee,@amount_c=@tran_amount
			,@descrip1=@descrip,@descrip2=@descrip1
			,@debit=@account,@credit=@recv_acc, @rate_items=1,@rate_amount=@conv_rate,@rate_reverse=0,@rate_flags=21
			,@lat_descrip=0,@tariff_kind=0,@info=0
			,@is_kassa=0,@rec_state=0,@add_tariff=0,@check_saldo=0
	
		IF @account_ccy <> 'GEL'
			SET @recv_acc = @conv_acc_v
		ELSE
			SET @recv_acc = @conv_acc_n

		SET @fee = @amount - @account_amount
		IF @fee > $0.004
		EXEC @r = dbo.ADD_DOC
			@rec_id OUTPUT,
			@user_id=@user_id,@dept_no=@dept_no,@doc_date=@today,
			@iso=@account_ccy,@amount=@fee,@doc_num=@doc_num,@op_code=@op_code,
			@debit=@account,@credit=@recv_acc,
			@rec_state=0,
			@descrip='ÊÏÍÅÄÒÔÀÝÉÉÓ ÓÀÊÏÌÉÓÉÏ',@owner=@user_id,
			@doc_type=12,@lat=@lat,@parent_rec_id=@rec_id,@add_tariff=0,@check_saldo=0
	END
	ELSE
	BEGIN
	EXEC @r = dbo.ADD_DOC
		@rec_id OUTPUT,
		@user_id=@user_id,@dept_no=@dept_no,@doc_date=@today,
		@iso=@account_ccy,@amount=@fee,@doc_num=@doc_num,@op_code=@op_code,
		@debit=@account,@credit=@recv_acc,
		@rec_state=0,
		@descrip='ÂÀÍÀÙÃÄÁÉÓ ÓÀÊÏÌÉÓÉÏ',@owner=@user_id,
		@doc_type=12,@lat=@lat,@parent_rec_id=@rec_id,@add_tariff=0,@check_saldo=0
	END
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
END

IF  @fee <= $0.004 AND @is_convert = 1
BEGIN
	IF @account_ccy <> 'GEL'
		SET @recv_acc = @conv_acc_v
	ELSE
		SET @recv_acc = @conv_acc_n

	SET @fee = @amount - @account_amount
	IF @fee > $0.004
	EXEC @r = dbo.ADD_DOC
		@rec_id OUTPUT,
		@user_id=@user_id,@dept_no=@dept_no,@doc_date=@today,
		@iso=@account_ccy,@amount=@fee,@doc_num=@doc_num,@op_code=@op_code,
		@debit=@account,@credit=@recv_acc,
		@rec_state=0,
		@descrip='ÊÏÍÅÄÒÔÀÝÉÉÓ ÓÀÊÏÌÉÓÉÏ',@owner=@user_id,
		@doc_type=12,@lat=@lat,@parent_rec_id=@rec_id,@add_tariff=0,@check_saldo=0
END

IF @tariff_amount > $0.004
BEGIN
	SET @recv_acc = CASE WHEN @account_ccy = 'GEL' THEN @fee_acc_n ELSE @fee_acc_v END
	SET @descrip = 'POS-ÉÓ ÏÐÄÒÀÝÉÀ: ' + CONVERT(VARCHAR(20), @tran_datetime, 20) + ' ÀÅÔ. ÊÏÃÉ: ' + @auth_code
	SET @account_extra = null

	IF dbo.acc_is_incasso(@recv_acc_n, 'GEL') = 1
	BEGIN
		SET @output_msg = CONVERT(varchar(15), @recv_acc_n) + '/GEL' + N' ანგარიშს ადევს ინკასო'
		SET @account_extra = @recv_acc_n
		SET @recv_acc_n = @acc_ofb_d
		SET @fee_acc_n = @acc_ofb_c
		SET @doc_type = 200
	END

	EXEC @r = dbo.ADD_DOC
		@rec_id OUTPUT,
		@user_id=@user_id,@dept_no=@dept_no,@doc_date=@today,
		@iso='GEL',@amount=@tariff_amount,@doc_num=@doc_num,@op_code=@op_code,
		@debit=@recv_acc_n,@credit=@fee_acc_n,
		@rec_state=0,
		@descrip=@descrip,@owner=@user_id,
		@doc_type=@doc_type,@lat=@lat,@parent_rec_id=0,@add_tariff=0,@check_saldo=0,@account_extra=@account_extra

	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
END


COMMIT TRAN

RETURN 0
GO
