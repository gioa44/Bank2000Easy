SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ADD_SWIFT_DOC]
  @swift_rec_id int,
  @user_id int /* who is adding the document */,
  @doc_date smalldatetime,
  @lat bit = 0,
  @rec_state smallint
AS

SET NOCOUNT ON

DECLARE 
  @rec_id int,
  @dt_open smalldatetime,
  @today smalldatetime
 
SET @today = convert(smalldatetime,floor(convert(real,getdate())))
SET @dt_open = dbo.bank_open_date()

IF @doc_date < @dt_open
BEGIN
  IF @lat = 0 
       RAISERROR ('<ERR>ÞÅÄËÉ ÈÀÒÉÙÉÈ ÓÀÁÖÈÉÓ ÃÀÌÀÔÄÁÀ ÀÒ ÛÄÉÞËÄÁÀ</ERR>',16,1)
  ELSE RAISERROR ('<ERR>Cannot add documets with an old date</ERR>',16,1)
  RETURN (3)
END

DECLARE 
	@op_num int,
	@aut_status tinyint,
	@dav_status varchar(20),
	@asaxva_status bit,
	@doc_date_in_doc smalldatetime,
	@aut_0 bit,

	@debit TACCOUNT,
	@credit TACCOUNT,
	@iso TISO,
	@amount money,
	@doc_num int,
	@op_code TOPCODE,
	@bnk_cli_id int,
	@descrip varchar(150),
	@owner int,
	@account_extra TACCOUNT,
	@prod_id int,
	@foreign_id int,
	@channel_id int,
	@dept_no int,

	@sender_bank_code TINTBANKCODE,
	@sender_acc TINTACCOUNT,
	@receiver_bank_code TINTBANKCODE,
	@receiver_acc TINTACCOUNT,
	@sender_bank_name varchar(100),
	@receiver_bank_name varchar(100),
	@sender_acc_name varchar(100),
	@receiver_acc_name varchar(100),
	@intermed_bank_code TINTBANKCODE,
	@intermed_bank_name varchar(100),
	@extra_info varchar(255),
	@swift_text varchar(4000),
	@ref_num varchar(32),
	@address_lat varchar(100), 
	@cor_bank_code TINTBANKCODE, 
	@cor_bank_name varchar(100)


DECLARE 
  @transit_acc_cre TACCOUNT,
  @transit_acc_deb TACCOUNT,
  @transit_acc_cre_2 TACCOUNT,
  @transit_acc_deb_2 TACCOUNT,

  @our_bank_code TINTBANKCODE,
  @our_bank_name TINTBANKCODE


EXEC dbo.GET_SETTING_ACC 'SWIFT_TRA_ACC_K_V', @transit_acc_cre OUTPUT
EXEC dbo.GET_SETTING_ACC 'SWIFT_TRA_ACC_D_V', @transit_acc_deb OUTPUT
EXEC dbo.GET_SETTING_ACC 'TRANSIT_ACC_CREDIT_V', @transit_acc_cre_2 OUTPUT
EXEC dbo.GET_SETTING_ACC 'TRANSIT_ACC_DEBIT_V', @transit_acc_deb_2 OUTPUT

EXEC dbo.GET_SETTING_STR 'OUR_BANK_CODE_INT', @our_bank_code OUTPUT
EXEC dbo.GET_SETTING_STR 'OUR_BANK_NAME_LAT', @our_bank_name OUTPUT


EXEC dbo.GET_SETTING_INT 'SW_AUT_0', @aut_0 OUTPUT
SELECT 
	@op_num = OP_NUM,  
	@aut_status = AUT_STATUS,
	@dav_status = DAV_STATUS,
	@asaxva_status = ASAXVA_STATUS,
	@doc_date_in_doc = DOC_DATE_IN_DOC,
	@iso = ISO,
	@amount = AMOUNT,
	@doc_num = DOC_NUM,
	@op_code = OP_CODE,
	@debit = DEBIT,
	@credit = CREDIT,
	@bnk_cli_id = BNK_CLI_ID,
	@descrip = DESCRIP,
	@owner = OWNER,
	@account_extra = ACCOUNT_EXTRA,
	@prod_id = PROD_ID,
	@foreign_id = FOREIGN_ID,
	@channel_id = CHANNEL_ID,
	@dept_no = DEPT_NO,

	@sender_bank_code = SENDER_BANK_CODE,
	@sender_acc = SENDER_ACC,
	@receiver_bank_code = RECEIVER_BANK_CODE,
	@receiver_acc = RECEIVER_ACC,
	@sender_bank_name = SENDER_BANK_NAME,
	@receiver_bank_name = RECEIVER_BANK_NAME,
	@sender_acc_name = SENDER_ACC_NAME,
	@receiver_acc_name = RECEIVER_ACC_NAME,
	@intermed_bank_code = INTERMED_BANK_CODE,
	@intermed_bank_name = INTERMED_BANK_NAME,
	@extra_info = EXTRA_INFO,
	@swift_text = SWIFT_TEXT,
	@ref_num = REF_NUM,
	@address_lat = ADDRESS_LAT, 
	@cor_bank_code = COR_BANK_CODE, 
	@cor_bank_name = COR_BANK_NAME
FROM dbo.SWIFT_DOCS
WHERE OP_NUM = @swift_rec_id

IF @aut_status = 0 AND @dav_status = 'ÂÀÖØÌÄÁÖËÉÀ' GOTO MoveData

IF @rec_state = 10 OR @aut_0 = 1
BEGIN
  IF @aut_status <> 0 OR @dav_status <> 'ÓßÏÒÉÀ' RETURN (0)
  IF @doc_date_in_doc >= @doc_date AND @asaxva_status = 0 RETURN (0)
END

SET @rec_state = CASE WHEN @doc_date_in_doc <= @doc_date THEN @rec_state ELSE 0 END

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

DECLARE 
	@r int,
	@credit1 TACCOUNT

SET @credit1 = CASE WHEN @doc_date_in_doc < @doc_date THEN @credit ELSE CASE WHEN @credit = @transit_acc_cre_2 THEN @credit ELSE @transit_acc_cre END END

EXEC @r = dbo.ADD_DOC_VALPLAT
		@rec_id = @rec_id OUTPUT,
		@user_id = @user_id,
		@owner = @owner,
		@doc_date = @doc_date,
		@doc_date_in_doc = @doc_date_in_doc,
		@debit = @debit,
		@credit = @credit1,
		@iso = @iso,
		@amount = @amount,
		@rec_state = @rec_state,
		@descrip = @descrip,
		@op_code = @op_code,
		@channel_id = @channel_id,
		@foreign_id = @foreign_id,
		@prod_id = @prod_id,
		@dept_no = @dept_no,
		@bnk_cli_id = @bnk_cli_id,
		@account_extra = @account_extra,

		@sender_bank_code = @sender_bank_code,
		@sender_acc = @sender_acc,
		@receiver_bank_code = @receiver_bank_code,
		@receiver_acc = @receiver_acc,
		@sender_bank_name = @sender_bank_name,
		@receiver_bank_name = @receiver_bank_name,
		@sender_acc_name = @sender_acc_name,
		@receiver_acc_name = @receiver_acc_name,
		@intermed_bank_code = @intermed_bank_code,
		@intermed_bank_name = @intermed_bank_name,
		@extra_info = @extra_info,
		@swift_text = @swift_text,
		@ref_num = @ref_num,
		--@address_lat = @address_lat, 
		@cor_bank_code = @cor_bank_code, 
		@cor_bank_name = @cor_bank_name
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

IF @doc_date_in_doc >= @doc_date and (@transit_acc_cre <> (SELECT CREDIT FROM dbo.SWIFT_DOCS WHERE OP_NUM = @swift_rec_id))
BEGIN
	EXEC @r = dbo.ADD_DOC_VALPLAT
			@rec_id = @rec_id OUTPUT,
			@user_id = @user_id,
			@owner = @owner,
			@doc_date = @doc_date_in_doc,
			@doc_date_in_doc = @doc_date_in_doc,
			@debit = @transit_acc_deb,
			@credit = @credit,
			@iso = @iso,
			@amount = @amount,
			@rec_state = 0,
			@descrip = @descrip,
			@op_code = @op_code,
			@channel_id = @channel_id,
			@foreign_id = @foreign_id,
			@prod_id = @prod_id,
			@dept_no = @dept_no,
			@bnk_cli_id = @bnk_cli_id,
			@account_extra = @account_extra,

			@sender_bank_code = @sender_bank_code,
			@sender_acc = @sender_acc,
			@receiver_bank_code = @receiver_bank_code,
			@receiver_acc = @receiver_acc,
			@sender_bank_name = @sender_bank_name,
			@receiver_bank_name = @receiver_bank_name,
			@sender_acc_name = @sender_acc_name,
			@receiver_acc_name = @receiver_acc_name,
			@intermed_bank_code = @intermed_bank_code,
			@intermed_bank_name = @intermed_bank_name,
			@extra_info = @extra_info,
			@swift_text = @swift_text,
			@ref_num = @ref_num,
			--@address_lat = @address_lat, 
			@cor_bank_code = @cor_bank_code, 
			@cor_bank_name = @cor_bank_name
  IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
END



MoveData:

INSERT INTO dbo.SWIFT_DOCS_ARC
SELECT * FROM dbo.SWIFT_DOCS
WHERE OP_NUM = @swift_rec_id
IF @@ERROR<>0 RETURN (10)

INSERT INTO dbo.SWIFT_CHANGES_ARC
SELECT * FROM dbo.SWIFT_CHANGES
WHERE DOC_REC_ID = @swift_rec_id
IF @@ERROR<>0 RETURN (10)

DELETE FROM dbo.SWIFT_DOCS
WHERE OP_NUM = @swift_rec_id
IF @@ERROR<>0 RETURN (10)

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN
RETURN (0)

GO
