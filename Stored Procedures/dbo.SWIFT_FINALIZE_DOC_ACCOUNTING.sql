SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[SWIFT_FINALIZE_DOC_ACCOUNTING]
	@doc_rec_id int,
	@user_id int,
	@_rec_id int OUTPUT
AS
SET NOCOUNT ON
DECLARE
	@tmp_rec_id int,
	@r int
DECLARE
	@head_branch_dept_no int,
	@fin_account2 TACCOUNT,
	@fin_conv_account TACCOUNT,
	@fin_account2_id int,
	@fin_conv_account_id int
 
EXEC @r = dbo.GET_SETTING_INT 'HEAD_BRANCH_DEPT_NO', @head_branch_dept_no OUTPUT
EXEC @r = dbo.GET_SETTING_ACC 'SWIFT_FIN_ACC', @fin_account2 OUTPUT
EXEC @r = dbo.GET_SETTING_ACC 'SWIFT_FIN_CONV_ACC', @fin_conv_account OUTPUT
 
DECLARE
	@parent_rec_id int,
	@trf_rec_id int,
	@trf_debit_id int,
	@trf_credit_id int,
	@trf_amount TAMOUNT

DECLARE
	@fin_date smalldatetime,
	@fin_iso TISO,
	@fin_amount TAMOUNT,
	@fin_account_id int,
	@fin_account TACCOUNT,
	@doc_iso TISO,
	@doc_amount TAMOUNT,
	@doc_type smallint,
	@sender_bank_code TINTBANKCODE,
	@sender_bank_name varchar(100),
	@sender_acc_name varchar(100),
	@receiver_bank_code TINTBANKCODE,
	@receiver_bank_name varchar(100),
	@receiver_acc_name varchar(100),
	@receiver_institution TINTBANKCODE,
	@our_bank_code TINTBANKCODE,
	@swift_text varchar(4000)

EXEC dbo.GET_SETTING_STR 'OUR_BANK_CODE_INT', @our_bank_code OUTPUT 
SELECT @doc_iso=ISO,@doc_amount=AMOUNT,@fin_iso=FIN_ISO,@fin_date=FIN_DATE,@fin_amount=FIN_AMOUNT, @fin_account_id=FIN_ACCOUNT_ID,
	@receiver_bank_code = RECEIVER_BANK_CODE, @receiver_bank_name = RECEIVER_BANK_NAME, @sender_bank_code = SENDER_BANK_CODE, @sender_bank_name = SENDER_BANK_NAME,
	@receiver_institution = RECEIVER_INSTITUTION, @swift_text = SWIFT_TEXT
FROM dbo.SWIFT_DOCS_IN
WHERE REC_ID=@doc_rec_id
SET @fin_account=dbo.acc_get_account(@fin_account_id)

SET @parent_rec_id = 0

IF @receiver_institution = 'DRESDEFF' AND @doc_iso = 'EUR' AND @fin_account = 72911
BEGIN
	SET @parent_rec_id = -1
	SET @trf_debit_id = dbo.acc_get_acc_id(@head_branch_dept_no, 804402141, @doc_iso)
	SET @trf_credit_id = @fin_account_id
	SET @trf_amount = CASE WHEN @doc_amount <= 12500 THEN $3.00 ELSE $10.00 END
END

IF @receiver_institution = 'DEUTDEFF' AND @doc_iso = 'EUR' AND @fin_account = 72704
BEGIN
	SET @parent_rec_id = -1
	SET @trf_debit_id = dbo.acc_get_acc_id(@head_branch_dept_no, 804402141, @doc_iso)
	SET @trf_credit_id = @fin_account_id
	SET @trf_amount = CASE
			WHEN @doc_amount <= $2500.00 THEN $3.00
			WHEN @doc_amount > $2500.00 AND @doc_amount <= $10000.00 THEN $7.00
			WHEN @doc_amount > $10000.00 AND @doc_amount <= $25000.00 THEN $8.50
			WHEN @doc_amount > $25000.00 AND @doc_amount <= $100000.00 THEN $12.50
			WHEN @doc_amount > $100000.00 THEN $15.00
		END
END

IF @receiver_institution = 'DRESDEFF' AND @doc_iso = 'EUR' AND @fin_account = 72911
BEGIN
	SET @parent_rec_id = -1
	SET @trf_debit_id = dbo.acc_get_acc_id(@head_branch_dept_no, 804402141, @doc_iso)
	SET @trf_credit_id = @fin_account_id
	SET @trf_amount = CASE WHEN @doc_amount <= 12500 THEN $3.00 ELSE $10.00 END
END


IF @receiver_institution = 'IMBKRUMM' AND @doc_iso = 'RUR' AND @fin_account = 171202001
BEGIN
	SET @parent_rec_id = -1
	SET @trf_debit_id = dbo.acc_get_acc_id(@head_branch_dept_no, 804402141, @doc_iso)
	SET @trf_credit_id = @fin_account_id
	SET @trf_amount = $6.00
END

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
BEGIN TRAN
SET @internal_transaction = 1
END
IF @receiver_bank_code = @sender_bank_code /* internal transfer */
SET @doc_type = 110
ELSE
IF @sender_bank_code = @our_bank_code
BEGIN
SET @doc_type = 112
IF EXISTS (SELECT * FROM dbo.DEPTS (NOLOCK) WHERE BIC = @receiver_bank_code)
SET @doc_type = 111
END
ELSE
IF @receiver_bank_code = @our_bank_code
BEGIN
SET @doc_type = 114
IF EXISTS (SELECT * FROM dbo.DEPTS (NOLOCK) WHERE BIC = @sender_bank_code)
SET @doc_type = 113
END
ELSE
SET @doc_type = 116

SET @fin_account2_id = dbo.acc_get_acc_id(@head_branch_dept_no, @fin_account2, @doc_iso)

IF @doc_iso = @fin_iso
BEGIN
	SELECT @sender_acc_name = DESCRIP_LAT 
	FROM dbo.ACCOUNTS (NOLOCK)
	WHERE ACC_ID = @fin_account2_id 

	SELECT @receiver_acc_name = DESCRIP_LAT 
	FROM dbo.ACCOUNTS (NOLOCK)
	WHERE ACC_ID = @fin_account_id 

	EXEC @r = dbo.ADD_DOC4
		@rec_id = @_rec_id OUTPUT,
		@user_id = @user_id,
		@doc_type = @doc_type,
		@doc_date = @fin_date,
		@doc_date_in_doc = @fin_date,
		@debit_id = @fin_account2_id,
		@credit_id = @fin_account_id,
		@iso = @fin_iso,
		@amount = @fin_amount,
		@rec_state = 22,
		@parent_rec_id = @parent_rec_id, 
		@descrip = 'ÓÀÊÏÒÄÓÐÏÍÃÄÍÔÏ ÀÍÂÀÒÉÛÉÓ ÂÀÃÀáÖÒÅÀ',
		@op_code = 'SWIFT',
		@sender_bank_code = @sender_bank_code,
		@sender_bank_name = @sender_bank_name,
		@sender_acc = @fin_account2,
		@sender_acc_name = @sender_acc_name,
		@receiver_bank_code = @sender_bank_code,
		@receiver_bank_name = @sender_bank_name,
		@receiver_acc = @fin_account,
		@receiver_acc_name = @sender_acc_name,
		@channel_id = 605,
		@foreign_id = @doc_rec_id,
		@swift_text = @swift_text
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

	EXEC @r = dbo.ADD_DOC4
		@rec_id = @trf_rec_id OUTPUT,
		@user_id = @user_id,
		@doc_type = 98,
		@doc_date = @fin_date,
		@doc_date_in_doc = @fin_date,
		@debit_id = @trf_debit_id,
		@credit_id = @trf_credit_id,
		@iso = @doc_iso,
		@amount = @trf_amount,
		@rec_state = 20,
		@parent_rec_id = @_rec_id, 
		@descrip = 'ÂÀÃÀÒÉÝáÅÀÆÄ ÌÏÌÓÀáÖÒÄÁÉÓ ÓÀÊÏÌÉÓÉÏ',
		@op_code = 'SCHRG',
		@channel_id = 605,
		@foreign_id = @doc_rec_id
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
END
ELSE
BEGIN
	SET @fin_conv_account_id = dbo.acc_get_acc_id(@head_branch_dept_no, @fin_conv_account, @fin_iso)
	EXEC @r = dbo.ADD_CONV_DOC4
		@_rec_id OUTPUT,
		@tmp_rec_id OUTPUT,
		@user_id = @user_id,
		@iso_d = @doc_iso, 
		@iso_c = @fin_iso,
		@amount_d = @doc_amount,
		@amount_c = @fin_amount,
		@debit_id = @fin_account2_id,
		@credit_id = @fin_conv_account_id,
		@doc_date = @fin_date, 
		@descrip1 = 'ÊÏÍÅÄÒÓÉÀ (ÂÀÚÉÃÅÀ)',
		@descrip2 = 'ÊÏÍÅÄÒÓÉÀ (ÚÉÃÅÀ)',
		@rec_state = 20
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
		SELECT @sender_acc_name = DESCRIP_LAT 
		FROM dbo.ACCOUNTS (NOLOCK)
		WHERE ACC_ID = @fin_conv_account_id 
		SELECT @receiver_acc_name = DESCRIP_LAT 
		FROM dbo.ACCOUNTS (NOLOCK)
		WHERE ACC_ID = @fin_account_id 
		EXEC @r = dbo.ADD_DOC4
			@rec_id = @_rec_id OUTPUT,
			@user_id = @user_id,
			@doc_type = @doc_type,
			@doc_date = @fin_date,
			@doc_date_in_doc = @fin_date,
			@debit_id = @fin_conv_account_id,
			@credit_id = @fin_account_id,
			@iso = @fin_iso,
			@amount = @fin_amount,
			@rec_state = 22,
			@descrip = 'ÓÀÊÏÒÄÓÐÏÍÃÄÍÔÏ ÀÍÂÀÒÉÛÉÓ ÂÀÃÀáÖÒÅÀ',
			@op_code = 'SWIFT',
			@sender_bank_code = @sender_bank_code,
			@sender_bank_name = @sender_bank_name,
			@sender_acc = @fin_conv_account,
			@sender_acc_name = @sender_acc_name,
			@receiver_bank_code = @sender_bank_code,
			@receiver_bank_name = @sender_bank_name,
			@receiver_acc = @fin_account,
			@receiver_acc_name = @sender_acc_name,
			@channel_id = 605,
			@foreign_id = @doc_rec_id,
			@swift_text = @swift_text
END
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END 
UPDATE dbo.SWIFT_DOCS_IN
SET FIN_DOC_REC_ID=@_rec_id, SWIFT_REC_STATE=60
WHERE REC_ID=@doc_rec_id
IF @@ERROR <>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END 

INSERT INTO SWIFT_DOCS_IN_CHANGES (DOC_REC_ID,USER_ID,DESCRIP) VALUES (@doc_rec_id,@user_id,'ÓÀÁÖÈÉÓ ÓÔÀÔÖÓÉÓ ÝÅËÉËÄÁÀ: ( 60 )');
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END 
IF @internal_transaction=1 AND @@TRANCOUNT>0 COMMIT TRAN
GO
