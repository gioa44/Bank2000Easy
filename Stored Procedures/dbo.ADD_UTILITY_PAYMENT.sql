SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ADD_UTILITY_PAYMENT]
	@rec_id int OUTPUT,
	@user_id int,
	@doc_date smalldatetime = NULL,
	@is_online bit = 1,
	@provider_id int = 0,
	@service_alias varchar(20),
	@id_in_provider varchar(50) = '',
	@id2_in_provider varchar(50) = null,
	@channel_id smallint = 0,
	@full_amount money,
	@tariff_amount money = $0.0,
	@owner int = NULL,
	@dept_no int = null,
	@lat bit = 0,

	@sender_acc TINTACCOUNT = NULL,
	@sender_acc_id int = NULL,

	@first_name varchar(50) = null,
	@last_name varchar(50) = null, 
	@fathers_name varchar(50) = null, 
	@birth_date smalldatetime = null, 
	@birth_place varchar(100) = null, 
	@address_jur varchar(100) = null, 
	@country varchar(2) = null, 
	@passport_type_id tinyint = 0, 
	@passport varchar(50) = null, 
	@personal_id varchar(20) = null,
	@reg_organ varchar(50) = null,
	@passport_issue_dt smalldatetime = null,
	@passport_end_date smalldatetime = null,

	@card_id varchar(19) = null,
	@card_type smallint = null,

	@ref_num varchar(100) = null,

	@send_time datetime = null,
    @account_extra TACCOUNT = null,
	@saxazkod varchar(11) = null,

	@descrip_scheduler varchar(100) = null
AS

SET NOCOUNT ON

DECLARE 
	@r int,
	@today smalldatetime,
	@up_amount money,
	@critical_amount money,
	@max_amount money,
	@doc_type int,
	@kas_acc TACCOUNT,
	@kas_acc_id int,
	@transit_acc TACCOUNT,
	@transit_acc_id int,
	@transit_acc_name varchar(100),
	@online_can_pay bit,
	@provider_name varchar(100),
	@service_name varchar(100),
	@profit_acc TACCOUNT,
	@credit_id int,
	@trec_id int,
	@par_rec_id int,
	@recv_tax_code varchar(11),
	@client_no int,

	@payment_rec_state int,
	@op_code varchar(5),
	@op_code_tariff varchar(5),
	@doc_rec_state int,
	@channel_percent int,
	@is_cash bit,
	@plat_inner tinyint,
	@plat_outer  tinyint,
	@plat_outer_branch  tinyint

IF ISNULL(@send_time, 0) < getdate()
	SET @send_time = getdate()

IF @dept_no IS NULL
	SET @dept_no = dbo.user_dept_no(@user_id)

IF @channel_id = 3
BEGIN
	SELECT @user_id  = [USER_ID]
	FROM	dbo.USERS (NOLOCK)
	WHERE [USER_NAME] = 'INTERNET' AND DEPT_NO = @dept_no
END

SELECT	@op_code=OP_CODE, @op_code_tariff=OP_CODE_TARIFF, @channel_percent=CHANNEL_PERCENT, @is_cash=IS_CASH, @payment_rec_state=REC_STATE, @plat_inner=PLAT_INNER, @plat_outer=PLAT_OUTER, @plat_outer_branch=PLAT_OUTER_BRANCH, @doc_rec_state=TRANSIT 
FROM	dbo.PAYMENT_CHANNELS
WHERE	CHANNEL_ID = @channel_id

SET @today = convert(smalldatetime,floor(convert(real,getdate())))
IF @doc_date IS NULL
	SET @doc_date = @today
ELSE
	SET @doc_date = convert(smalldatetime,floor(convert(real,@doc_date)))
IF @send_time < @doc_date
	SET @send_time =DATEADD(hour, 4, @doc_date)

SET @up_amount = @full_amount - @tariff_amount

SELECT	@provider_name = PROVIDER_NAME
FROM	dbo.PAYMENT_PROVIDERS (NOLOCK)
WHERE	PROVIDER_ID = @provider_id
	
SELECT	@online_can_pay = ONLINE_CAN_PAY, @transit_acc_id = TRANSIT_ACCOUNT, @service_name = CASE WHEN @lat = 0 THEN SERVICE_NAME ELSE SERVICE_NAME_LAT END,
		@recv_tax_code = RECV_TAX_CODE, @critical_amount = CRITICAL_AMOUNT, @max_amount = MAX_AMOUNT
FROM dbo.PAYMENT_PROVIDER_SERVICES (NOLOCK)
WHERE PROVIDER_ID = @provider_id and SERVICE_ALIAS = @service_alias

IF @up_amount > @max_amount
BEGIN
	RAISERROR('ÂÀÃÀÓÀáÃÄËÉ ÈÀÍáÀ ÀÙÄÌÀÔÄÁÀ ÂÀÃÀáÃÉÓ ËÉÌÉÔÓ!',16,1)
	RETURN 1
END

IF @transit_acc_id IS NULL
BEGIN
	RAISERROR('ÊÏÌÖÍÀËÖÒÉ ÂÀÃÀÓÀáÀÃÄÁÉÓ ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉ ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ',16,1)
	RETURN 2
END

SELECT @transit_acc = ACCOUNT, @transit_acc_name = DESCRIP
FROM dbo.ACCOUNTS (NOLOCK)
WHERE ACC_ID = @transit_acc_id

IF @transit_acc_name IS NULL
BEGIN
	RAISERROR('ÊÏÌÖÍÀËÖÒÉ ÂÀÃÀÓÀáÀÃÄÁÉÓ ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉ ÀÒ ÌÏÉÞÄÁÍÀ',16,1)
	RETURN 3
END

EXEC dbo.GET_DEPT_ACC @dept_no, 'UP_PROFIT_ACC', @profit_acc OUTPUT

IF @profit_acc IS NULL
BEGIN
	RAISERROR('ÊÏÌÖÍÀËÖÒÉ ÂÀÃÀÓÀáÀÃÄÁÉÓ ÓÀÔÀÒÉ×Ï ÀÍÂÀÒÉÛÉ ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ',16,1)
	RETURN 4
END

IF @channel_id > 0 AND ISNULL(@sender_acc_id, 0) = 0
BEGIN
	RAISERROR('ÊËÉÄÍÔÉÓ ÀÍÂÀÒÉÛÉÓ ÉÃÄÍÔÉ×ÉÊÀÔÏÒÉ ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ',16,1)
	RETURN 5
END

SET @sender_acc = dbo.acc_get_account(@sender_acc_id)

IF @online_can_pay = 0
	SET @is_online = 0

IF @tariff_amount > $0.000
	SET @par_rec_id = -1
ELSE
	SET @par_rec_id = 0

DECLARE @descrip varchar(150)
SET @descrip = ISNULL(@provider_name,'') + ', ' + ISNULL(@service_name, '') + ': ' + ISNULL(@id_in_provider, '')

IF ISNULL(@descrip_scheduler, '') <> ''
	SET @descrip = @descrip_scheduler

DECLARE 
	@internal_transaction bit

SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

EXEC @r = dbo.ON_USER_BEFORE_ADD_UTILITY_PAYMENT 
			@user_id=@user_id, @is_online=@is_online, @provider_id=@provider_id,
			@service_alias=@service_alias, @id_in_provider=@id_in_provider, @id2_in_provider=@id2_in_provider,
			@card_id=@card_id, @card_type=@card_type, @channel_id=@channel_id, @full_amount=@full_amount,
			@tariff_amount=@tariff_amount, @owner=@owner, @dept_no=@dept_no
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 6 END


IF @is_cash = 1	-- Cash
BEGIN
	--სალაროს შემოსავლის ორდერი 120-დან  129-მდე
	SET @doc_type = 120
	EXEC dbo.GET_DEPT_ACC @dept_no, 'KAS_ACC', @kas_acc OUTPUT

	--EXEC dbo.GET_SETTING_INT 'PMT_KAS', @doc_rec_state OUTPUT
	SET @kas_acc_id = dbo.acc_get_acc_id(dbo.dept_branch_id(@dept_no), @kas_acc, 'GEL')

	IF @up_amount > @critical_amount
		SET @doc_rec_state = 0

	SET @descrip = @descrip + '. ÈÀÍáÀ: ' + CONVERT(VARCHAR(12), @up_amount)

	EXEC @r = dbo.ADD_DOC4
		@rec_id OUTPUT,
		@user_id=@user_id,@dept_no=@dept_no,@doc_date=@doc_date,
		@iso='GEL',@amount=@full_amount,@doc_num=0,@op_code='04',
		@debit_id=@kas_acc_id,
		--@debit_acc=@kas_acc,
		--@credit_branch_id=@dept_no,
		@credit_id=@transit_acc_id,
		@rec_state=@doc_rec_state,
		@descrip=@descrip,@owner=@owner,
		@doc_type=@doc_type,
		@lat=@lat,@channel_id=778,
		@first_name = @first_name,
		@last_name = @last_name, 
		@fathers_name = @fathers_name, 
		@birth_date = @birth_date, 
		@birth_place = @birth_place, 
		@address_jur = @address_jur, 
		@country = @country, 
		@parent_rec_id=@par_rec_id,
		@passport_type_id = @passport_type_id, 
		@passport = @passport, 
		@personal_id = @personal_id,
		@reg_organ = @reg_organ,
		@passport_issue_dt = @passport_issue_dt,
		@passport_end_date = @passport_end_date,
		@foreign_id = 0,
		@add_tariff = 0,
		@flags = 0x300302,
		@treasury_code=@saxazkod,
		@account_extra=@account_extra
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 7 END

	SELECT @doc_rec_state = REC_STATE
	FROM dbo.OPS_0000 (NOLOCK)
	WHERE REC_ID = @rec_id

	IF @tariff_amount > $0.000
	BEGIN
		--EXEC dbo.GET_SETTING_STR 'PMT_TARIFF', @op_code OUTPUT
		SET @credit_id = dbo.acc_get_acc_id(dbo.dept_branch_id(@dept_no), @profit_acc, 'GEL')

		EXEC @r = dbo.ADD_DOC4
			@trec_id OUTPUT,
			@user_id=@user_id,@dept_no=@dept_no,@doc_date=@doc_date,
			@iso='GEL',@amount=@tariff_amount,@doc_num=0,@op_code=@op_code_tariff,
			@debit_id=@transit_acc_id,
			@credit_id=@credit_id,
			--@credit=@profit_acc,
			@rec_state=@doc_rec_state,
			@parent_rec_id=@rec_id,
			@descrip='ÊÏÌÖÍÀËÖÒÉ ÂÀÃÀÓÀáÀÃÉÓ ÓÀÊÏÌÉÓÉÏ',@owner=@owner,
			@doc_type=12,@lat=@lat,
			@add_tariff = 0

		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 8 END
	END
END
ELSE -- Plat
--IF @payment_type BETWEEN 1 AND 9
BEGIN
	--@doc_type BETWEEN 100 AND 109
	DECLARE
		@recv_acc TINTACCOUNT,
		@recv_acc_ofline TINTACCOUNT,
		@recv_acc_online TINTACCOUNT,
		@recv_acc_name varchar(100),
		@sender_acc_name varchar(100),
		@receiver_bank_code TGEOBANKCODE,
		@sender_bank_code TGEOBANKCODE,
		@receiver_bank_name varchar(50),
		@sender_bank_name varchar(50),
		@sender_tax_code varchar(11)
	
	SET @sender_bank_code = dbo.acc_get_bank_code(@sender_acc_id)
	SET @sender_acc_name = dbo.acc_get_name(@sender_acc_id)

	SELECT	@sender_bank_name = DESCRIP
	FROM	dbo.DEPTS(NOLOCK)
	WHERE	DEPT_NO = dbo.acc_get_dept_no(@sender_acc_id)

	SELECT	@recv_acc_ofline = RECV_ACC, @recv_acc_online = RECV_ACC_ONLINE, @recv_acc_name = RECV_ACC_NAME, @receiver_bank_code = RECV_BANK_CODE
	FROM	dbo.PAYMENT_PROVIDER_SERVICES (NOLOCK)
	WHERE	PROVIDER_ID = @provider_id and SERVICE_ALIAS = @service_alias


	SELECT @sender_tax_code = CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END, @client_no = A.CLIENT_NO
	FROM dbo.ACCOUNTS A (NOLOCK) 
		LEFT OUTER JOIN dbo.CLIENTS C(NOLOCK) ON A.CLIENT_NO = C.CLIENT_NO
	WHERE A.ACC_ID = @sender_acc_id

	SELECT @receiver_bank_name = DESCRIP
	FROM dbo.BANKS(NOLOCK)
	WHERE CODE9 = @receiver_bank_code

	IF @is_online = 1
		SET @recv_acc = @recv_acc_online
	ELSE
		SET @recv_acc = @recv_acc_ofline

	SET @doc_type = 100


	SET @doc_rec_state = ISNULL(@doc_rec_state, 0)

	IF @up_amount > @critical_amount
		SET @doc_rec_state = 0


	EXEC @r = dbo.ADD_DOC4
		@rec_id OUTPUT,
		@user_id=@user_id,@dept_no=@dept_no,@doc_date=@doc_date,@doc_date_in_doc=@doc_date,@rec_date=@doc_date,
		@iso='GEL',@amount=@up_amount,@doc_num=1,@op_code=@op_code,
		@debit_id=@sender_acc_id,
		@credit_id=@transit_acc_id,
		@rec_state=@doc_rec_state,
		@descrip=@descrip,@owner=@owner,@doc_type=100,
		@receiver_bank_code=@receiver_bank_code,@receiver_bank_name=@receiver_bank_name,
		@receiver_tax_code=@recv_tax_code,
		@sender_acc=@sender_acc,@sender_acc_name=@sender_acc_name,
		@sender_bank_code=@sender_bank_code,@sender_bank_name=@sender_bank_name,
		@sender_tax_code=@sender_tax_code,
		@receiver_acc=@recv_acc,@receiver_acc_name=@recv_acc_name,
		@lat=@lat,@channel_id=778,
		@foreign_id = 0,
		@add_tariff = 0,
		@flags = 0x300302,
		@account_extra=@account_extra, @saxazkod=@saxazkod

	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 9 END

	SELECT @doc_rec_state = REC_STATE
	FROM dbo.OPS_0000 (NOLOCK)
	WHERE REC_ID = @rec_id

	IF @tariff_amount > $0.000
	BEGIN
		--EXEC dbo.GET_SETTING_STR 'PMT_TARIFF', @op_code OUTPUT
		SET @dept_no = dbo.on_user_get_payment_profit_acc_dept_no(@user_id, @dept_no, @sender_acc_id)
		SET @credit_id = dbo.acc_get_acc_id(dbo.dept_branch_id(@dept_no), @profit_acc, 'GEL')

		EXEC @r = dbo.ADD_DOC4
			@trec_id OUTPUT,
			@user_id=@user_id,@dept_no=@dept_no,@doc_date=@doc_date,
			@iso='GEL',@amount=@tariff_amount,@doc_num=1,@op_code=@op_code_tariff,
			@debit_id=@sender_acc_id,
			@credit_id=@credit_id,
			--@credit=@profit_acc,
			@rec_state=@doc_rec_state,
			@parent_rec_id=@rec_id,
			@descrip='ÊÏÌÖÍÀËÖÒÉ ÂÀÃÀÓÀáÀÃÉÓ ÓÀÊÏÌÉÓÉÏ',@owner=@owner,
			@doc_type=12,@lat=@lat,
			@add_tariff = 0
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 10 END
	END
END


INSERT INTO dbo.PENDING_PAYMENTS (DOC_REC_ID, IS_ONLINE, PROVIDER_ID, SERVICE_ALIAS, DOC_TYPE, OWNER, DEPT_NO, CHANNEL_ID, REC_STATE, DT_TM, AMOUNT, ID_IN_PROVIDER, ID2_IN_PROVIDER, CARD_ID, CARD_TYPE, INFO, REF_NUM, DESCRIP)
VALUES (@rec_id,@is_online,@provider_id,@service_alias,@doc_type,@user_id,@dept_no,@channel_id,@payment_rec_state,@send_time,@up_amount,@id_in_provider,@id2_in_provider,@card_id, @card_type, null, @ref_num, @descrip_scheduler)
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 12 END

IF @is_online = 0 AND @doc_rec_state >= 20 AND @payment_rec_state <> 3
BEGIN
	EXEC @r = dbo.CHANGE_PAYMENT_DOC_STATE  @doc_rec_id=@rec_id, @rec_state=3, @lock_flag=0,
		@user_id=@user_id, @descrip='ÓÀÁÖÈÄÁÉÓ ÀÅÔÏÒÉÆÀÝÉÄÁÉ ÀÒÀÓßÏÒÀÃÀÀ ÌÉÈÉÈÄÁÖËÉ!'
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 13 END
END

IF @is_online = 1 AND (@doc_rec_state >= 20 OR @payment_rec_state = 1)
BEGIN
	EXEC @r = dbo.CHANGE_PAYMENT_DOC_STATE  @doc_rec_id=@rec_id, @rec_state=1, @lock_flag=0,
		@user_id=@user_id, @descrip='ÓÀÁÖÈÄÁÉÓ ÀÅÔÏÒÉÆÀÝÉÄÁÉ ÀÒÀÓßÏÒÀÃÀÀ ÌÉÈÉÈÄÁÖËÉ!'
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 14 END
END

EXEC @r = dbo.ON_USER_AFTER_ADD_UTILITY_PAYMENT @rec_id=@rec_id, @user_id=@user_id, @is_online=@is_online, @provider_id=@provider_id, @service_alias=@service_alias,
			@id_in_provider=@id_in_provider, @id2_in_provider=@id2_in_provider, @card_id=@card_id, @card_type=@card_type, @channel_id=@channel_id, @full_amount=@full_amount, @tariff_amount=@tariff_amount, @owner=@owner, @dept_no=@dept_no
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 15 END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN 0
GO
