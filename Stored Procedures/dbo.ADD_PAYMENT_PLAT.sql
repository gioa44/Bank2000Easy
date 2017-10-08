SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ADD_PAYMENT_PLAT]
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
	@sender_bank_code int,
	@doc_type tinyint,
	@dept_no int,
	@amount money,
	@tariff_amount money,
	@today smalldatetime,
	@tmp_date smalldatetime,
	@user_id int,
	@transit_acc TACCOUNT,
	@transit_acc_id int,
	@transit_acc_name varchar(100),
	@debit_branch_id int,

	@descrip varchar(150),
	@recv_tax_code varchar(11),
	@receiver_bank_code varchar(50),
	@recv_acc varchar(50),
	@recv_acc_name varchar(100),
	@sender_acc varchar(50),
	@sender_acc_id int,
	@sender_acc_name varchar(100),
	@sender_tax_code varchar(11),
	@charge_name varchar(100),
	@descrip_template varchar(100),
	@credit TACCOUNT,
	@credit_id int,
	@rec_state int,
	@provider_name varchar(100),
	@service_name varchar(100),

	@descrip_scheduler varchar(100),

	@up_profit_acc varchar(50),
	@ref_num varchar(100),

	@provider_moneyback_percent money,
	@provider_moneyback_min_amount money,
	@provider_moneyback_account_id int,

	@op_code varchar(5),
	@channel_id int,

	@payment_rec_state int,
	@op_code_tariff varchar(5),
	@doc_rec_state int,
	@channel_percent int,
	@is_cash bit,
	@plat_inner tinyint,
	@plat_outer tinyint,
	@saxazkod varchar(9),
	@charge_type bit,
	@head_branch_dept_no int,
	@client_no int

SET @rec_state = 0

SELECT	@provider_id = PROVIDER_ID, @service_alias = SERVICE_ALIAS, 
		@user_id = OWNER, @dept_no = DEPT_NO, @amount = AMOUNT, @id_in_provider = ID_IN_PROVIDER,
		@id2_in_provider = ID2_IN_PROVIDER, @channel_id = CHANNEL_ID, @ref_num = REF_NUM, @descrip_scheduler=DESCRIP
FROM dbo.PENDING_PAYMENTS (NOLOCK)
WHERE DOC_REC_ID = @rec_id

SELECT	@op_code = OP_CODE, @op_code_tariff = OP_CODE_TARIFF, @channel_percent = CHANNEL_PERCENT, @is_cash = IS_CASH,
		@payment_rec_state = REC_STATE, @plat_inner = PLAT_INNER, @plat_outer = PLAT_OUTER,	@doc_rec_state = TRANSIT
FROM	dbo.PAYMENT_CHANNELS (NOLOCK)
WHERE	CHANNEL_ID = @channel_id

SET @today = convert(smalldatetime,floor(convert(real,GETDATE())))

SELECT @provider_name = PROVIDER_NAME
FROM dbo.PAYMENT_PROVIDERS (NOLOCK)
WHERE PROVIDER_ID = @provider_id

SELECT @transit_acc_id = TRANSIT_ACCOUNT, @service_name = [SERVICE_NAME],
	@provider_moneyback_percent = PROVIDER_MONEYBACK_PERCENT, 
	@provider_moneyback_min_amount = PROVIDER_MONEYBACK_TARIFF, 
	@provider_moneyback_account_id = PROVIDER_MONEYBACK_ACCOUNT,
	@charge_type = CHARGE_TYPE
FROM dbo.PAYMENT_PROVIDER_SERVICES (NOLOCK)
WHERE PROVIDER_ID = @provider_id and SERVICE_ALIAS = @service_alias

IF @transit_acc_id IS NULL
BEGIN
	RAISERROR('ÊÏÌÖÍÀËÖÒÉ ÂÀÃÀÓÀáÀÃÄÁÉÓ ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉ ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ',16,1)
	RETURN 1
END

SELECT @sender_acc = ACCOUNT, @transit_acc_name = DESCRIP, @debit_branch_id = dbo.dept_branch_id(DEPT_NO)
FROM dbo.ACCOUNTS (NOLOCK)
WHERE ACC_ID = @transit_acc_id

IF @transit_acc_name IS NULL
BEGIN
	RAISERROR('ÊÏÌÖÍÀËÖÒÉ ÂÀÃÀÓÀáÀÃÄÁÉÓ ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉ ÀÒ ÌÏÉÞÄÁÍÀ',16,1)
	RETURN 2
END

SET @transit_acc = @sender_acc
SET @sender_bank_code = dbo.acc_get_bank_code(@transit_acc_id)

EXEC dbo.GET_DEPT_ACC @dept_no, 'PROV_MONEYBACK_ACC', @up_profit_acc OUTPUT

IF @up_profit_acc IS NULL
BEGIN
	RAISERROR('ÊÏÌÖÍÀËÖÒÉ ÂÀÃÀÓÀáÀÃÄÁÉÓ ÐÒÏÅÀÉÃÄÒÉÓ ÓÀÔÀÒÉ×Ï ÀÍÂÀÒÉÛÉ(ÂÀÍÚÏ×ÉËÄÁÄÁÉ ÃÀ ×ÉËÉÀËÄÁÉ) ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ',16,1)
	RETURN 3
END

IF @provider_moneyback_account_id IS NULL
BEGIN
	RAISERROR('ÐÒÏÅÀÉÃÄÒÉÃÀÍ ÃÀÓÀÁÒÖÍÄÁÄËÉ ÐÒÏÝÄÍÔÉÓ ÀÍÂÀÒÉÛÉ ÀÒ ÌÏÉÞÄÁÍÀ',16,1)
	RETURN 4
END

DECLARE @suffix varchar(100)

SET @suffix = NULL

IF @is_cash = 0
BEGIN
	SELECT @sender_acc_id = D.DEBIT_ID, @sender_acc = A.ACCOUNT, @sender_acc_name = A.DESCRIP, @tmp_date = D.DOC_DATE, @saxazkod = DP.SAXAZKOD, @client_no = CLIENT_NO
	FROM dbo.OPS_0000 D (NOLOCK)
		INNER JOIN dbo.ACCOUNTS A (NOLOCK) ON A.ACC_ID = D.DEBIT_ID
		LEFT OUTER JOIN dbo.DOC_DETAILS_PLAT DP (NOLOCK) ON DP.DOC_REC_ID = D.REC_ID
	WHERE D.REC_ID = @rec_id

	IF @sender_acc_id IS NULL
		SELECT @sender_acc_id = D.DEBIT_ID, @sender_acc = A.ACCOUNT, @sender_acc_name = A.DESCRIP, @tmp_date = D.DOC_DATE,	@saxazkod = DP.SAXAZKOD, @client_no = CLIENT_NO
		FROM dbo.OPS_ARC D (NOLOCK) 
			INNER JOIN dbo.ACCOUNTS A (NOLOCK) ON A.ACC_ID = D.DEBIT_ID
			LEFT OUTER JOIN dbo.DOC_DETAILS_ARC_PLAT DP (NOLOCK) ON DP.DOC_REC_ID = D.REC_ID
		WHERE D.REC_ID = @rec_id

	SET @sender_bank_code = dbo.acc_get_bank_code(@sender_acc_id)

	IF @client_no IS NOT NULL
	BEGIN
		SELECT 
			@sender_tax_code = CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END,
			@suffix = 
			CASE WHEN C.IS_RESIDENT = 0 THEN 
				CASE WHEN C.IS_JURIDICAL = 1 THEN '' ELSE ISNULL(', ' + C.PASSPORT, '') END + ISNULL(', ' + CC.DESCRIP, '') 
			ELSE 
				CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN ', ' + C.TAX_INSP_CODE ELSE ', ' + C.PERSONAL_ID END
			END
		FROM dbo.CLIENTS C (NOLOCK)
			LEFT JOIN dbo.COUNTRIES CC (NOLOCK) ON CC.COUNTRY = CASE WHEN C.IS_JURIDICAL = 1 THEN C.COUNTRY ELSE C.PASSPORT_COUNTRY END
		WHERE C.CLIENT_NO = @client_no
	END
END
ELSE
BEGIN
	SELECT @sender_acc_id = D.DEBIT_ID, @sender_acc_name = ISNULL(P.FIRST_NAME,'') + ' ' + ISNULL(P.LAST_NAME,''),
		@tmp_date = D.DOC_DATE, 
		@sender_tax_code = CASE WHEN ISNULL(D.TAX_CODE_OR_PID, '') = '' THEN P.PERSONAL_ID ELSE D.TAX_CODE_OR_PID END, @saxazkod = D.TREASURY_CODE,
		@suffix = 
			CASE WHEN ISNULL(D.TAX_CODE_OR_PID, '') = '' THEN 
				CASE WHEN ISNULL(P.COUNTRY, '') IN ('GE', '') THEN ISNULL(', ' + P.PERSONAL_ID, '') ELSE ISNULL(', ' + P.PASSPORT, '') + ISNULL(', ' + CC.DESCRIP, '') END
			ELSE
				ISNULL(', ' + D.TAX_CODE_OR_PID, '')
			END
	FROM dbo.OPS_0000 D (NOLOCK)
		INNER JOIN dbo.DOC_DETAILS_PASSPORTS P (NOLOCK) ON P.DOC_REC_ID = D.REC_ID
		LEFT JOIN dbo.COUNTRIES CC (NOLOCK) ON CC.COUNTRY = P.COUNTRY
	WHERE D.REC_ID = @rec_id

	IF @sender_acc_id IS NULL
		SELECT	@sender_acc_id = D.DEBIT_ID, @sender_acc_name = ISNULL(P.FIRST_NAME,'') + ' ' + ISNULL(P.LAST_NAME,''),
			@tmp_date = D.DOC_DATE, 
			@sender_tax_code = CASE WHEN ISNULL(D.TAX_CODE_OR_PID, '') = '' THEN P.PERSONAL_ID ELSE D.TAX_CODE_OR_PID END, @saxazkod = D.TREASURY_CODE,
			@suffix = 
				CASE WHEN ISNULL(D.TAX_CODE_OR_PID, '') = '' THEN 
					CASE WHEN ISNULL(P.COUNTRY, '') IN ('GE', '') THEN ISNULL(', ' + P.PERSONAL_ID, '') ELSE ISNULL(', ' + P.PASSPORT, '') + ISNULL(CC.DESCRIP, '') END
				ELSE
					ISNULL(D.TAX_CODE_OR_PID, '')
				END		
			FROM dbo.OPS_ARC D (NOLOCK)
				INNER JOIN dbo.DOC_DETAILS_PASSPORTS P (NOLOCK) ON P.DOC_REC_ID = D.REC_ID
				LEFT JOIN dbo.COUNTRIES CC (NOLOCK) ON CC.COUNTRY = P.COUNTRY
		WHERE D.REC_ID = @rec_id

	SET @sender_bank_code = dbo.acc_get_bank_code(@sender_acc_id)
END

SET @sender_acc_name = @sender_acc_name + ISNULL(@suffix, '')

IF (@today < @tmp_date)
	SET @today = @tmp_date

SELECT @service_id = SERVICE_ID, @receiver_bank_code = RECV_BANK_CODE, @recv_acc = RECV_ACC, @recv_acc_name = RECV_ACC_NAME, 
	@recv_tax_code = RECV_TAX_CODE, @charge_name = CASE WHEN @lat = 0 THEN [SERVICE_NAME] ELSE [SERVICE_NAME_LAT] END,
	@descrip_template = CASE WHEN @lat = 0 THEN DESCRIP_TEMPLATE ELSE DESCRIP_TEMPLATE_LAT END
FROM dbo.PAYMENT_PROVIDER_SERVICES (NOLOCK)
WHERE PROVIDER_ID = @provider_id AND SERVICE_ALIAS = @service_alias

SET @descrip_template = REPLACE(@descrip_template, '%ref_num%', ISNULL(@ref_num, ''))
SET @descrip_template = REPLACE(@descrip_template, '%id2%', ISNULL(@id2_in_provider, ''))
SET @descrip_template = REPLACE(@descrip_template, '%date%', convert(varchar(18), GETDATE(), 105))
SET @descrip_template = REPLACE(@descrip_template, '%time%', convert(varchar(18), GETDATE(), 108))

SET @descrip = ''
EXEC master..xp_sprintf @descrip OUTPUT, @descrip_template, @id_in_provider

IF ISNULL(@descrip_scheduler, '') <> ''
	SET @descrip = @descrip_scheduler

IF dbo.bank_is_geo_bank_in_our_db(@receiver_bank_code) <> 0 /* internal transfer */
BEGIN
	SET @doc_type = 100
	SET @credit = convert(decimal(15,0), @recv_acc)

	SELECT TOP 1 @credit_id = A.ACC_ID
	FROM dbo.ACCOUNTS A (NOLOCK)
		INNER JOIN dbo.DEPTS D (NOLOCK) ON D.BRANCH_ID = A.BRANCH_ID
	WHERE D.CODE9 = @receiver_bank_code AND D.IS_DEPT = 0 AND A.ACCOUNT = @credit AND A.ISO = 'GEL' AND NOT A.REC_STATE IN (2, 128)
	ORDER BY D.DEPT_NO
	SET @rec_state = @plat_inner
END
ELSE
BEGIN
    EXEC dbo.GET_SETTING_ACC 'CORR_ACC_NA', @credit OUTPUT
	EXEC dbo.GET_SETTING_INT 'HEAD_BRANCH_DEPT_NO', @head_branch_dept_no OUTPUT
	SET @credit_id = dbo.acc_get_acc_id (@head_branch_dept_no, @credit, 'GEL')

	SET @doc_type = 102
	SET @rec_state = @plat_outer
	IF @rec_state >= 20
		SET @rec_state = 20
	ELSE
	IF @rec_state >= 10
		SET @rec_state = 10
END

DECLARE @extra_info varchar(250)

SET @extra_info = dbo.payments_get_extra_info(@rec_id, @transit_acc_id, ISNULL(@provider_name,'') + ', ' + ISNULL(@service_name, ''))

DECLARE 
	@internal_transaction bit

SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

SET @tariff_amount = $0.0000
IF(ISNULL(@provider_moneyback_percent, $0) > $0.000) AND (@provider_moneyback_account_id IS NOT NULL)
	SET @tariff_amount = ROUND((@amount * @provider_moneyback_percent ) / 100.0, 2)
IF @tariff_amount < ISNULL(@provider_moneyback_min_amount, $0.0000)
	SET @tariff_amount = @provider_moneyback_min_amount

DECLARE
	@parent_rec_id int,
	@sender_bank_name varchar(105),
	@receiver_bank_name varchar(105),
	@info_message varchar(255),
	@flags int

SET @flags = 0
--SET @flags = @flags | 0x00000004 --საბუთის წაშლა
SET @flags = @flags | 0x00000040 --თანხის შეცვლა
SET @flags = @flags | 0x00000080 --დებეტის ანგარიშის შეცვლა
SET @flags = @flags | 0x00000200 --დანიშნულების შეცვლა
SET @flags = @flags | 0x00080000 --გამგზავნის ანგარიში 
SET @flags = @flags | 0x00200000 --მიმღების ანგარიში

SELECT @sender_bank_name = DESCRIP 
FROM dbo.BANKS (NOLOCK)
WHERE CODE9 = @sender_bank_code

SELECT @receiver_bank_name = DESCRIP 
FROM dbo.BANKS (NOLOCK)
WHERE CODE9 = @receiver_bank_code

IF @tariff_amount > $0.0000
	SET @parent_rec_id = -1
ELSE
	SET @parent_rec_id = 0

IF @charge_type = 1
BEGIN
	SET @amount = @amount - @tariff_amount
	SET @provider_moneyback_account_id = @transit_acc_id
END

EXEC @r = dbo.ADD_DOC4
	@rec_id OUTPUT,
	@user_id=@user_id,@dept_no=@dept_no,@doc_date=@today,@doc_date_in_doc=@today,@doc_type=@doc_type,
	@iso='GEL',@amount=@amount,@doc_num=1,@op_code=@op_code,
	@sender_acc=@sender_acc,@sender_acc_name=@sender_acc_name,@sender_tax_code=@sender_tax_code,
	@debit_id=@transit_acc_id, @credit_id=@credit_id, @sender_bank_code=@sender_bank_code, @sender_bank_name=@sender_bank_name,
	@receiver_bank_code=@receiver_bank_code, @receiver_acc=@recv_acc, @receiver_acc_name=@recv_acc_name, @receiver_tax_code=@recv_tax_code, @receiver_bank_name=@receiver_bank_name,
	@rec_state=@rec_state,@parent_rec_id=@parent_rec_id,@foreign_id=@rec_id,
	@descrip=@descrip,@extra_info=@extra_info,@saxazkod=@saxazkod,@rec_date=@today,@flags=@flags,
	@lat=@lat,@channel_id=778,@prod_id=@service_id,@add_tariff=0, @info_message=@info_message OUTPUT

IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 5 END


IF @tariff_amount > $0.0000
BEGIN

	SET @credit_id = dbo.acc_get_acc_id(dbo.dept_branch_id(@dept_no), @up_profit_acc, 'GEL')

	EXEC @r = dbo.ADD_DOC4
			@rec_id OUTPUT,
			@user_id=@user_id,@dept_no=@dept_no,@doc_date=@today,
			@iso='GEL',@amount=@tariff_amount,@doc_num=1,@op_code=@op_code_tariff,
			@debit_id=@provider_moneyback_account_id,
			@credit_id=@credit_id,
			@rec_state=@rec_state, @parent_rec_id=@rec_id,
			@descrip='ÊÏÌÖÍÀËÖÒÉ ÂÀÃÀÓÀáÀÃÉÓ ÓÀÊÏÌÉÓÉÏ',@owner=@user_id,
			@doc_type=12,@lat=@lat,@add_tariff=0

	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 6 END
END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN
--ROLLBACK

RETURN 0
GO
