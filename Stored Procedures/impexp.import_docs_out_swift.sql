SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [impexp].[import_docs_out_swift]
	@date smalldatetime,
	@por int,
	@user_id int,
	@is_close_day bit = 0
AS

SET NOCOUNT ON;

BEGIN TRAN

DECLARE
	@corr_account_va TACCOUNT,
	@corr_account_va2 TACCOUNT,
	@count int

EXEC dbo.GET_SETTING_ACC 'CORR_ACC_VA', @corr_account_va OUTPUT
IF ISNULL(@corr_account_va, 0) = 0
BEGIN
	RAISERROR ('ÐÀÒÀÌÄÔÒÉ "ÓÀÊÏÒ. ÀÍÂÀÒÉÛÉ (ÅÀËÖÔÀ, ÂÀÃÀÒÉÝáÅÀ)" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ ÓÉÓÔÄÌÉÓ ÊÏÍ×ÉÂÖÒÀÝÉÀÛÉ.', 16, 1)
	IF @@TRANCOUNT > 0 ROLLBACK 
END

EXEC dbo.GET_SETTING_ACC 'CORR_ACC_VA2', @corr_account_va2 OUTPUT
IF @corr_account_va2 = 0
	SET @corr_account_va2 = NULL

DECLARE @head_branch_id int
SET @head_branch_id = dbo.bank_head_branch_id()


DECLARE
	@r int,
	@skip bit,
	@rec_id int,
	@doc_num int,
	@doc_date smalldatetime,
	@portion int,
	@old_flags int,
	@iso TISO,
	@amount money,
	@amount_equ money,
	@doc_credit_id int,
	@ref_num varchar(32),
	@descrip varchar(150),
    @sender_bank_code varchar(37),
	@sender_bank_name varchar(105),
	@sender_acc varchar(37),
	@sender_acc_name varchar(105),
	@sender_address_lat varchar(105),
	@receiver_address_lat varchar(105),
	@receiver_bank_code varchar(37),
	@receiver_bank_name varchar(105),
	@receiver_acc varchar(37),
	@receiver_acc_name varchar(105),
	@intermed_bank_code varchar(37),
	@intermed_bank_name varchar(105),
	@intermed_bank_code2 varchar(37),
	@intermed_bank_name2 varchar(105),
	@cor_bank_code varchar(37),
	@cor_bank_name varchar(105),
	@correspondent_bank_id int,
	@extra_info varchar(255),
	@extra_info_descrip bit,
	@det_of_charg char(3),
	@swift_flags_1 int,
	@swift_flags_2 int

DECLARE
	@op_code TOPCODE,
	@account_extra TACCOUNT

DECLARE cr CURSOR FOR
SELECT D.REC_ID, D.DOC_NUM, D.DOC_DATE, D.FLAGS, D.ISO, D.AMOUNT, D.AMOUNT_EQU, D.CREDIT_ID, D.DESCRIP,
    DD.SENDER_BANK_CODE, DD.SENDER_BANK_NAME, DD.SENDER_ACC, DD.SENDER_ACC_NAME, DD.SENDER_ADDRESS_LAT,
	DD.RECEIVER_BANK_CODE, DD.RECEIVER_BANK_NAME, DD.RECEIVER_ACC, DD.RECEIVER_ACC_NAME, DD.RECEIVER_ADDRESS_LAT,
	DD.INTERMED_BANK_CODE, DD.INTERMED_BANK_NAME, DD.COR_BANK_CODE, DD.COR_BANK_NAME,
	DD.EXTRA_INFO, DD.EXTRA_INFO_DESCRIP, DD.DET_OF_CHARG, D.OP_CODE, D.ACCOUNT_EXTRA
FROM dbo.OPS_0000 D (UPDLOCK)
	INNER JOIN dbo.DOC_DETAILS_VALPLAT DD(NOLOCK) ON D.REC_ID = DD.DOC_REC_ID
	INNER JOIN dbo.ACCOUNTS A(NOLOCK) ON A.ACC_ID = D.CREDIT_ID
WHERE A.BRANCH_ID = @head_branch_id AND (A.ACCOUNT = @corr_account_va OR (@corr_account_va2 IS NOT NULL AND A.ACCOUNT = @corr_account_va2)) AND A.ISO = D.ISO AND
	D.DOC_DATE <= @date AND D.DOC_TYPE IN (112,116) AND (D.REC_STATE BETWEEN 20 AND 24) AND 
	NOT EXISTS (SELECT * FROM impexp.DOCS_OUT_SWIFT A WHERE A.DOC_REC_ID = D.REC_ID)
ORDER BY D.REC_ID

OPEN cr

FETCH NEXT FROM cr
INTO @rec_id, @doc_num, @doc_date, @old_flags, @iso, @amount, @amount_equ, @doc_credit_id, @descrip,
    @sender_bank_code, @sender_bank_name, @sender_acc, @sender_acc_name, @sender_address_lat,
	@receiver_bank_code, @receiver_bank_name, @receiver_acc, @receiver_acc_name, @receiver_address_lat,
	@intermed_bank_code, @intermed_bank_name, @cor_bank_code, @cor_bank_name,
	@extra_info, @extra_info_descrip, @det_of_charg, @op_code, @account_extra 

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @skip = 0
	SET @ref_num = impexp.get_ref_num(@rec_id, @doc_date, @op_code, @account_extra)
	SET @correspondent_bank_id = NULL
	SET @swift_flags_1 =
		1		-- REF_NUM
		| 4		-- Reciver Bank
	SET @swift_flags_2 = 0

	SET @portion = CASE WHEN @is_close_day = 1 THEN 0 ELSE impexp.get_portion_swift(@rec_id) END

	EXEC @r = impexp.on_user_before_import_docs_out_swift 
		@rec_id = @rec_id, @is_close_day = @is_close_day, 
		@portion_date = @date, @portion = @portion OUTPUT,
		@doc_num = @doc_num, @doc_date = @doc_date, 
		@iso = @iso, @amount = @amount, @amount_equ = @amount_equ,
		@doc_credit_id = @doc_credit_id OUTPUT,	@ref_num = @ref_num OUTPUT, @descrip = @descrip OUTPUT,
		@sender_bank_code = @sender_bank_code OUTPUT, @sender_bank_name = @sender_bank_name OUTPUT,
		@sender_acc = @sender_acc OUTPUT, @sender_acc_name = @sender_acc_name OUTPUT, @sender_address_lat = @sender_address_lat OUTPUT,
		@receiver_bank_code = @receiver_bank_code OUTPUT, @receiver_bank_name = @receiver_bank_name OUTPUT,
		@receiver_acc = @receiver_acc OUTPUT, @receiver_acc_name = @receiver_acc_name OUTPUT,
		@intermed_bank_code = @intermed_bank_code OUTPUT, @intermed_bank_name = @intermed_bank_name OUTPUT,
		@intermed_bank_code2 = @intermed_bank_code2 OUTPUT, @intermed_bank_name2 = @intermed_bank_name2 OUTPUT,
		@cor_bank_code = @cor_bank_code,	@cor_bank_name = @cor_bank_name,
		@correspondent_bank_id = @correspondent_bank_id OUTPUT,	@extra_info = @extra_info OUTPUT, @extra_info_descrip = @extra_info_descrip OUTPUT,
		@det_of_charg = @det_of_charg OUTPUT, @swift_flags_1 = @swift_flags_1 OUTPUT, @swift_flags_2 = @swift_flags_2 OUTPUT,
		@op_code = @op_code, @account_extra = @account_extra,
		@skip = @skip OUTPUT
	IF @r <> 0 OR @@ERROR <> 0 GOTO err_


	IF @skip = 0
	BEGIN
		SET @det_of_charg = CASE WHEN ISNULL(@det_of_charg, '') = '' THEN 'OUR' ELSE @det_of_charg END
		
		SET @descrip = impexp.get_swift_string(@descrip)
		SET @sender_bank_code = impexp.get_swift_string(@sender_bank_code)
		SET @sender_bank_name = impexp.get_swift_string(@sender_bank_name)
		SET @sender_acc = impexp.get_swift_string(@sender_acc)
		SET @sender_acc_name = impexp.get_swift_string(@sender_acc_name)
		SET @sender_address_lat = impexp.get_swift_string(@sender_address_lat)
		SET @receiver_bank_code = impexp.get_swift_string(@receiver_bank_code)
		SET @receiver_bank_name = impexp.get_swift_string(@receiver_bank_name)
		SET @receiver_acc = impexp.get_swift_string(@receiver_acc)
		SET @receiver_acc_name = impexp.get_swift_string(@receiver_acc_name)
		SET @receiver_address_lat = impexp.get_swift_string(@receiver_address_lat)
		SET @intermed_bank_code = impexp.get_swift_string(@intermed_bank_code)
		SET @intermed_bank_name = impexp.get_swift_string(@intermed_bank_name)
		SET @cor_bank_code = impexp.get_swift_string(@cor_bank_code)
		SET @cor_bank_name = impexp.get_swift_string(@cor_bank_name)
		SET @extra_info = impexp.get_swift_string(@extra_info)
		SET @extra_info_descrip = impexp.get_swift_string(@extra_info_descrip)

		INSERT INTO impexp.DOCS_OUT_SWIFT(DOC_REC_ID, [UID], DOC_DATE, PORTION_DATE, PORTION, OLD_FLAGS,
			ISO, AMOUNT, AMOUNT_EQU, DOC_CREDIT_ID, REF_NUM, DESCRIP, 
			SENDER_BANK_CODE, SENDER_BANK_NAME,	SENDER_ACC, SENDER_ACC_NAME, SENDER_ADDRESS_LAT, 
			RECEIVER_BANK_CODE, RECEIVER_BANK_NAME, 	RECEIVER_ACC, RECEIVER_ACC_NAME, RECEIVER_ADDRESS_LAT,
			INTERMED_BANK_CODE, INTERMED_BANK_NAME, INTERMED_BANK_CODE2, INTERMED_BANK_NAME2,
			CORRESPONDENT_BANK_ID, EXTRA_INFO, EXTRA_INFO_DESCRIP, DET_OF_CHARG,
			CLOSE_TIME, EXPORT_TIME, FINISH_TIME, FINALYZE_DATE, FINALYZE_BANK_ID, FINALYZE_ACC_ID, FINALYZE_AMOUNT, FINALYZE_ISO, FINALYZE_DOC_REC_ID, SWIFT_TEXT, SWIFT_FILENAME,
			[STATE], SWIFT_FLAGS_1, SWIFT_FLAGS_2, OP_CODE)
		VALUES(@rec_id, 0, @doc_date, @date, @portion, @old_flags,
			@iso, @amount, @amount_equ, @doc_credit_id, @ref_num, @descrip, 
			@sender_bank_code, @sender_bank_name, @sender_acc, @sender_acc_name, @sender_address_lat, 
			@receiver_bank_code, @receiver_bank_name, @receiver_acc, @receiver_acc_name, @receiver_address_lat,
			@intermed_bank_code, @intermed_bank_name, @intermed_bank_code2, @intermed_bank_name2,
			@correspondent_bank_id, @extra_info, @extra_info_descrip, @det_of_charg,
			NULL, NULL, NULL, NULL, NULL, NULL, NULL,NULL, NULL, NULL, NULL,
			11, @swift_flags_1, @swift_flags_2, @op_code)
		IF @@ERROR <> 0 GOTO err_

		UPDATE dbo.OPS_0000
		SET FLAGS = 1, [UID] = [UID] + 1, REC_STATE = 25
		WHERE REC_ID = @rec_id
		IF @@ERROR <> 0 GOTO err_

		INSERT INTO dbo.DOC_CHANGES (DOC_REC_ID,[USER_ID],DESCRIP) 
		VALUES (@rec_id, @user_id, 'ÓÀÁÖÈÉÓ ÂÀÃÀÔÀÍÀ ÉÌÐÏÒÔ-ÄØÓÐÏÒÔÉÓ ÌÏÃÖËÛÉ')
		IF @@ERROR <> 0 GOTO err_

		INSERT INTO impexp.DOCS_OUT_SWIFT_CHANGES(DOC_REC_ID, [USER_ID], CHANGE_TYPE, DESCRIP)
		VALUES(@rec_id, @user_id, 21, 'ÓÀÁÖÈÉÓ ÜÀÔÅÉÒÈÅÀ')
		IF @@ERROR <> 0 GOTO err_
	END
	
	FETCH NEXT FROM cr
	INTO @rec_id, @doc_num, @doc_date, @old_flags, @iso, @amount, @amount_equ, @doc_credit_id, @descrip,
		@sender_bank_code, @sender_bank_name, @sender_acc, @sender_acc_name, @sender_address_lat,
		@receiver_bank_code, @receiver_bank_name, @receiver_acc, @receiver_acc_name, @receiver_address_lat,
		@intermed_bank_code, @intermed_bank_name, @cor_bank_code, @cor_bank_name,
		@extra_info, @extra_info_descrip, @det_of_charg, @op_code, @account_extra
END

CLOSE cr
DEALLOCATE cr


DELETE FROM impexp.PORTIONS_OUT_SWIFT
WHERE PORTION_DATE = @date AND PORTION = -1
IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

COMMIT
RETURN

err_:

CLOSE cr
DEALLOCATE cr
IF @@TRANCOUNT > 0 ROLLBACK
RETURN 1
GO
