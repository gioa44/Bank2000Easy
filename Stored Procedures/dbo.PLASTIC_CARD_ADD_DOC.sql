SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[PLASTIC_CARD_ADD_DOC]
	@user_id int,
	@merchant_id int,
	@card_id varchar(19),
	@date datetime,
	@amount TAMOUNT,
	@fee TAMOUNT,
	@ccy char(3),
	@ref_num varchar(12),
	@proc_region char(1) = 'L',
	@is_merchant_info bit = 0, -- ინფორმაცია არის მერჩანტის ფაილიდან
	@lat bit = 0
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
	@op_code varchar(5),
	@our_bank_code TGEOBANKCODE,
	@our_bank_name varchar(100),
	@recv_bank_name varchar(100),
	@credit TACCOUNT,
	@debit TACCOUNT,
	@is_branch bit,
	@rec_state int,
	@doc_type int,
	@r int,
	@dept_no int,
	@today smalldatetime,
	@descrip varchar(150),
	@is_our_card bit,
	@is_our_merchant bit,
	@merchant_type tinyint,
	@rate_amount TAMOUNT

SET @today = convert(smalldatetime,floor(convert(real,getdate())))

SELECT @dept_no=DEPT_NO
FROM USERS
WHERE [USER_ID] = @user_id

IF EXISTS(SELECT * FROM dbo.PLASTIC_CARDS WHERE CARD_ID = @card_id)
	SET @is_our_card = 1
ELSE
	SET @is_our_card = 0

-- ჩვენი ბარათის და მერჩჩანტის ფაილის შემთხვევაში არ ვაკეთებთ გატარებას, რადგან ეს ინფორმაციე ემატება LO-ფაილიდან
IF @is_our_card = 1 AND @is_merchant_info = 1
	RETURN 0

SELECT @debit = ACCOUNT
FROM dbo.PLASTIC_CARD_ACCOUNTS
WHERE CARD_ID = @card_id AND ISO = @ccy

IF @debit IS NULL AND (@is_our_card = 1 OR @is_merchant_info = 0)-- ბარათზე მიბმული ანგარიში არა ემთხვევა ს.ც-დან მიღებულ ანგარიშს!
	RETURN(1)

SET @is_our_merchant = 1 -- ჩვენი მერჩანტი

IF NOT EXISTS(SELECT * FROM dbo.PLASTIC_CARD_MERCHANTS WHERE MERCHANT_ID = @merchant_id)
BEGIN
	SET @merchant_id = 9999999
	SET @amount = @amount + @fee
	SET @is_our_merchant = 0
END

SELECT	@recv_bank_code = RECV_BANK_CODE, @recv_acc_n = RECV_ACC_N, @recv_acc_v = RECV_ACC_V,
		@recv_acc_name = RECV_ACC_NAME, @op_code = OP_CODE, @merchant_type = MERCHANT_TYPE
FROM dbo.PLASTIC_CARD_MERCHANTS
WHERE MERCHANT_ID = @merchant_id

IF @is_merchant_info = 1 --მერჩანტის ფაილი
BEGIN
	SELECT @sender_acc_n = SENDER_ACC_N, @sender_acc_v = SENDER_ACC_V, @sender_acc_name = SENDER_ACC_NAME
	FROM PLASTIC_CARD_OTHER_CARDS
	WHERE MERCHANT_TYPE = @merchant_type
END

--ჩვენი ბარათის შემთხვევაში დასახელებას ვიღებ ანგარიშებიდან
IF @is_our_card = 1
	SELECT @sender_acc_name = DESCRIP
	FROM dbo.ACCOUNTS
	WHERE ACCOUNT = @debit AND ISO = @ccy

IF @is_our_card = 0 AND @is_our_merchant = 0
	RETURN 1

IF @ccy = 'GEL'
BEGIN
	SET @recv_acc = @recv_acc_n
	IF @is_merchant_info = 1
		SET @debit = @sender_acc_n
END
ELSE
BEGIN
	SET @recv_acc = @recv_acc_v
	IF @is_merchant_info = 1
		SET @debit = @sender_acc_v
END

EXEC dbo.GET_SETTING_INT 'OUR_BANK_CODE', @our_bank_code OUTPUT
EXEC GET_SETTING_STR 'OUR_BANK_NAME', @our_bank_name OUTPUT

EXEC @r = dbo.BCC_CHECK_RECV_BANK_GEO @recv_bank_code, @recv_bank_name OUTPUT, @credit OUTPUT, @is_branch OUTPUT, 'GEL', @lat
IF @@ERROR <> 0 OR @r <> 0 RETURN(8)

SET @descrip = 'ÈÀÍáÉÓ ÌÏáÓÍÀ: ' + CONVERT(VARCHAR(20), @date, 20)-- + ' ' + @ref_num

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

IF @proc_region = 'E' AND @ccy = 'GEL'
BEGIN
-- კონვერტაცია
DECLARE
	@rec_id_2 int,
	@amount_c TAMOUNT,
	@descrip1 varchar(50)

	--EXEC dbo.GET_AMOUNT_BY_RATE 'USD', @today, @amount, @amount_c OUTPUT

	SELECT @rate_amount = AMOUNT / ITEMS
	FROM  VAL_RATES
	WHERE ISO='USD' and DT = (SELECT MAX(DT) FROM VAL_RATES WHERE (ISO='USD') and (DT<=@today))

	SET @amount_c = @amount / @rate_amount

	SET @descrip1 = 'ÊÏÍÅÄÒÓÉÀ (ÊÒÏÓ-ÊÖÒÓÉ: 1 USD = ' + CONVERT(VARCHAR(15), @rate_amount) + ' GEL)'

	EXEC @r=ADD_CONV_DOC @rec_id OUTPUT,@rec_id_2 OUTPUT,@user_id=@user_id,@dept_no=@dept_no
	,@op_code=@op_code,@doc_date=@today,@iso_d=@ccy,@iso_c='USD',@amount_d=@amount,@amount_c=@amount_c
	,@descrip1=@descrip,@descrip2=@descrip1
	,@debit=@sender_acc_n,@credit=@recv_acc_v,@rate_items=1,@rate_amount=@rate_amount,@rate_reverse=-1,@rate_flags=21
	,@lat_descrip=0,@tariff_kind=0,@info=0
	,@is_kassa=0,@rec_state=0

END
ELSE
EXEC @r = dbo.ADD_DOC
	@rec_id OUTPUT,
	@user_id=@user_id,@dept_no=@dept_no,@doc_date=@today,@doc_date_in_doc=@today,
	@iso=@ccy,@amount=@amount,@doc_num=0,@op_code=@op_code,
	@sender_acc=@debit,@sender_acc_name=@sender_acc_name,@debit=@debit,
	@receiver_bank_code=@recv_bank_code, @receiver_acc=@recv_acc, @receiver_acc_name=@recv_acc_name,
	@rec_state=@rec_state,@descrip=@descrip,
	--@extra_info=@extra_info,@lat=@lat,
	--@receiver_tax_code=@recv_tax_code,@channel_id=778,@prod_id=@service_id,@foreign_id=@rec_id,@parent_rec_id=@parent_rec_id,,@add_tariff=0
	@sender_bank_code=@our_bank_code,@sender_bank_name=@our_bank_name,
	@doc_type=@doc_type, @credit=@credit, @receiver_bank_name=@recv_bank_name

IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN 0
GO
