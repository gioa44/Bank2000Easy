SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ADD_CANCELED_PLAT] 
	@rec_id int,
	@lat bit = 0
AS

SET NOCOUNT ON

DECLARE
	@r int,
	@provider_id int,
	@service_id int,
	@service_alias varchar(20),
	@id_in_provider varchar(50),
	@id2_in_provider varchar(50),
	@our_bank_code TGEOBANKCODE,
	@doc_type tinyint,
	@dept_no int,
	@amount money,
	@tariff_amount money,
	@today smalldatetime,
	@user_id int,
	@transit_acc TACCOUNT,
	@transit_acc_name varchar(100),

	@descrip varchar(150),
	@sender_tax_code int,
	@recv_bank_code TINTBANKCODE,
	@recv_acc TINTACCOUNT,
	@recv_acc_name varchar(100),
	@sender_acc TINTACCOUNT,
	@sender_acc_name varchar(100),
	@charge_name varchar(100),
	@descrip_template varchar(100),
	@credit TACCOUNT,
	@is_branch bit,
	@rec_state int,
	@provider_name varchar(100),
	@service_name varchar(100),

	@ref_num varchar(100),

	@moneyback_transit_account TINTACCOUNT,
	@moneyback_transit_account_name varchar(100),

	@op_code varchar(5),
	@channel_id int,

	@payment_rec_state int,
	@op_code_tariff varchar(5),
	@doc_rec_state int,
	@channel_percent int,
	@is_cash bit,
	@plat_inner tinyint,
	@plat_outer  tinyint,
	@plat_outer_branch  tinyint

SET @today = convert(smalldatetime,floor(convert(real,getdate())))
SET @rec_state = 0

EXEC dbo.GET_SETTING_INT 'OUR_BANK_CODE', @our_bank_code OUTPUT

SELECT	@provider_id = PROVIDER_ID, @service_alias = SERVICE_ALIAS, 
		@user_id = OWNER, @dept_no = DEPT_NO, @amount = AMOUNT, @id_in_provider = ID_IN_PROVIDER,
		@id2_in_provider = ID2_IN_PROVIDER, @channel_id = CHANNEL_ID, @ref_num = REF_NUM
FROM dbo.PENDING_PAYMENTS
WHERE DOC_REC_ID = @rec_id

SELECT	@op_code=OP_CODE, @op_code_tariff=OP_CODE_TARIFF, @channel_percent=CHANNEL_PERCENT, @is_cash=IS_CASH,
		@payment_rec_state=REC_STATE, @plat_inner=PLAT_INNER, @plat_outer=PLAT_OUTER,
		@plat_outer_branch=PLAT_OUTER_BRANCH, @doc_rec_state=TRANSIT 
FROM	dbo.PAYMENT_CHANNELS
WHERE	CHANNEL_ID = @channel_id

SELECT @provider_name = PROVIDER_NAME
FROM dbo.PAYMENT_PROVIDERS (NOLOCK)
WHERE PROVIDER_ID = @provider_id

SELECT	@transit_acc = TRANSIT_ACCOUNT, @service_name = SERVICE_NAME,
		@moneyback_transit_account = MONYBACK_TRANSIT_ACCOUNT
FROM dbo.PAYMENT_PROVIDER_SERVICES (NOLOCK)
WHERE PROVIDER_ID = @provider_id and SERVICE_ALIAS = @service_alias

IF @transit_acc IS NULL
BEGIN
	RAISERROR('ÊÏÌÖÍÀËÖÒÉ ÂÀÃÀÓÀáÀÃÄÁÉÓ ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉ ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ',16,1)
	RETURN 11
END

SELECT @transit_acc_name = DESCRIP
FROM dbo.ACCOUNTS (NOLOCK)
WHERE ACCOUNT = @transit_acc AND ISO = 'GEL'

IF @transit_acc_name IS NULL
BEGIN
	RAISERROR('ÊÏÌÖÍÀËÖÒÉ ÂÀÃÀÓÀáÀÃÄÁÉÓ ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉ ÀÒ ÌÏÉÞÄÁÍÀ',16,1)
	RETURN 12
END

IF @moneyback_transit_account IS NULL
BEGIN
	RAISERROR('ÊÏÌÖÍÀËÖÒÉ ÂÀÃÀÓÀáÀÃÄÁÉÓ ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉ(2) ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ',16,1)
	RETURN 13
END

SELECT @moneyback_transit_account_name = DESCRIP
FROM dbo.ACCOUNTS (NOLOCK)
WHERE ACCOUNT = @moneyback_transit_account AND ISO = 'GEL'

IF @moneyback_transit_account_name IS NULL
BEGIN
	RAISERROR('ÊÏÌÖÍÀËÖÒÉ ÂÀÃÀÓÀáÀÃÄÁÉÓ ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉ(2) ÀÒ ÌÏÉÞÄÁÍÀ',16,1)
	RETURN 14
END

IF @channel_id > 0
BEGIN
	SELECT @recv_acc = A.ACCOUNT, @recv_acc_name = A.DESCRIP
	FROM dbo.OPS_0000 D (NOLOCK)
		INNER JOIN dbo.ACCOUNTS A (NOLOCK) ON A.ACC_ID = D.DEBIT_ID
	WHERE D.REC_ID = @rec_id
END
ELSE
BEGIN
	SET @recv_acc = @moneyback_transit_account
	SET @recv_acc_name = @moneyback_transit_account_name
END

SELECT @service_id = SERVICE_ID, @sender_acc = RECV_ACC, @sender_acc_name = RECV_ACC_NAME, 
       @sender_tax_code = RECV_TAX_CODE, @charge_name = CASE WHEN @lat = 0 THEN SERVICE_NAME ELSE SERVICE_NAME_LAT END,
       @descrip_template = CASE WHEN @lat = 0 THEN DESCRIP_TEMPLATE ELSE DESCRIP_TEMPLATE_LAT END
FROM dbo.PAYMENT_PROVIDER_SERVICES
WHERE PROVIDER_ID = @provider_id AND SERVICE_ALIAS = @service_alias

SET @descrip_template = REPLACE(@descrip_template, '%ref_num%', ISNULL(@ref_num, ''))
SET @descrip_template = REPLACE(@descrip_template, '%id2%', ISNULL(@id2_in_provider, ''))
SET @descrip_template = REPLACE(@descrip_template, '%date%', convert(varchar(18), GETDATE(), 105))
SET @descrip_template = REPLACE(@descrip_template, '%time%', convert(varchar(18), GETDATE(), 108))

SET @descrip = 'ÈÀÍáÉÓ ÃÀÁÒÖÍÄÁÀ: '
EXEC master..xp_sprintf @descrip OUTPUT, @descrip_template, @id_in_provider

SET @recv_bank_code = @our_bank_code

IF @recv_bank_code = @our_bank_code /* internal transfer */
BEGIN
	SET @doc_type = 100
	SET @credit = convert(decimal(15,0),@recv_acc)
	SET @rec_state = @plat_inner
END


DECLARE @extra_info varchar(250)

SET @extra_info = ISNULL(@provider_name,'') + ', ' + ISNULL(@service_name, '')

DECLARE 
	@internal_transaction bit

SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

DECLARE @parent_rec_id int

SET @parent_rec_id = 0

EXEC @r = dbo.ADD_DOC_PLAT
	@rec_id OUTPUT,
	@user_id=@user_id,@dept_no=@dept_no,@doc_date=@today,@doc_date_in_doc=@today,
	@iso='GEL',@amount=@amount,@doc_num=0,@op_code=@op_code,
	@sender_acc=@sender_acc,@sender_acc_name=@sender_acc_name,@debit=@transit_acc,
	@receiver_bank_code=@recv_bank_code, @receiver_acc=@recv_acc, @receiver_acc_name=@recv_acc_name,
	@sender_tax_code=@sender_tax_code,
	@rec_state=@rec_state,@parent_rec_id=@parent_rec_id,@foreign_id=@rec_id,
	@descrip=@descrip,@extra_info=@extra_info,
	@lat=@lat,@channel_id=778,@prod_id=@service_id,@add_tariff=0

IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 15 END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN 0
GO
