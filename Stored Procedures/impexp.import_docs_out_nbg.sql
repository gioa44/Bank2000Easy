SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [impexp].[import_docs_out_nbg] 
	@date smalldatetime,
	@por int,
	@user_id int,
	@is_close_day bit = 0
AS

SET NOCOUNT ON;

BEGIN TRAN

DECLARE @r int
EXEC @r = impexp.check_portion_state_out_nbg @date, @por, @user_id, 1, default, default, 'ÉÌÐÏÒÔÉ'
IF @@ERROR <> 0 OR @r <> 0 BEGIN ROLLBACK RETURN 1 END

EXEC @r = impexp.on_user_prepare_before_import_docs_out_nbg	@date, @por, @user_id, @is_close_day
IF @@ERROR <> 0 OR @r <> 0 BEGIN ROLLBACK RETURN 1 END

DECLARE
	@corr_account_na TACCOUNT,
	@credit_id int,
	@debit_id int

EXEC dbo.GET_SETTING_ACC 'CORR_ACC_NA', @corr_account_na OUTPUT
IF ISNULL(@corr_account_na, 0) = 0
BEGIN
	RAISERROR ('ÐÀÒÀÌÄÔÒÉ "ÓÀÊÏÒ. ÀÍÂÀÒÉÛÉ (ËÀÒÉ, ÂÀÃÀÒÉÝáÅÀ)" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ ÓÉÓÔÄÌÉÓ ÊÏÍ×ÉÂÖÒÀÝÉÀÛÉ.', 16, 1)
	IF @@TRANCOUNT > 0 ROLLBACK 
END

DECLARE @head_branch_id int
SET @head_branch_id = dbo.bank_head_branch_id()

DECLARE @head_code3 char(3)
SELECT @head_code3 = SUBSTRING(CONVERT(char(9), CODE9), 7, 3)
FROM dbo.DEPTS (NOLOCK)
WHERE DEPT_NO = @head_branch_id 

SET @credit_id = dbo.acc_get_acc_id (@head_branch_id, @corr_account_na, 'GEL')

DECLARE
	@skip bit,
	@rec_id int,
	@portion_date smalldatetime,
	@portion int,
	@old_flags int,
	@doc_num int,
	@doc_date smalldatetime,
	@doc_date_in_doc smalldatetime,
	@rec_date smalldatetime,
	@amount money,
	@descrip varchar(150),
    @sender_bank_code TINTBANKCODE,
	@sender_bank_name varchar(50),
	@sender_acc TINTACCOUNT,
	@sender_acc_name varchar(100),
	@sender_tax_code varchar(11),
	@sender_tax_code0 varchar(11),
	@receiver_bank_code TINTBANKCODE,
	@receiver_bank_name varchar(50),
	@receiver_acc TINTACCOUNT,
	@receiver_acc_name varchar(100),
	@receiver_tax_code varchar(11),
	@extra_info varchar(250),
	@saxazkod varchar(11),
	@tax_payer_name varchar(100)

DECLARE
	@op_code TOPCODE,
	@account_extra TACCOUNT,
	@suffix varchar(100)

DECLARE cc CURSOR FOR
SELECT D.REC_ID, D.DOC_NUM, D.DOC_DATE, D.DOC_DATE_IN_DOC, DD.REC_DATE, D.FLAGS, D.AMOUNT, D.DESCRIP,
    DD.SENDER_BANK_CODE, DD.SENDER_BANK_NAME, DD.SENDER_ACC, DD.SENDER_ACC_NAME, 
	SENDER_TAX_CODE, CASE WHEN LTRIM(RTRIM(ISNULL(DD.TAX_PAYER_NAME, ''))) <> '' THEN DD.TAX_PAYER_TAX_CODE ELSE DD.SENDER_TAX_CODE END,
	DD.RECEIVER_BANK_CODE, DD.RECEIVER_BANK_NAME, DD.RECEIVER_ACC, DD.RECEIVER_ACC_NAME, DD.RECEIVER_TAX_CODE,
	DD.EXTRA_INFO, DD.SAXAZKOD, D.OP_CODE, D.ACCOUNT_EXTRA, DD.TAX_PAYER_NAME, D.DEBIT_ID
FROM dbo.OPS_0000 D (UPDLOCK)
	INNER JOIN dbo.DOC_DETAILS_PLAT DD(NOLOCK) ON D.REC_ID = DD.DOC_REC_ID
WHERE D.DOC_DATE <= @date AND D.DOC_TYPE IN (102,106) AND (D.REC_STATE BETWEEN 20 AND 24) AND (D.CREDIT_ID = @credit_id) AND 
	NOT EXISTS (SELECT * FROM impexp.DOCS_OUT_NBG A WHERE A.DOC_REC_ID = D.REC_ID)
ORDER BY REC_ID

OPEN cc

FETCH NEXT FROM cc
INTO @rec_id, @doc_num, @doc_date, @doc_date_in_doc, @rec_date, @old_flags, @amount, @descrip,
    @sender_bank_code, @sender_bank_name, @sender_acc, @sender_acc_name, @sender_tax_code0, @sender_tax_code,
	@receiver_bank_code, @receiver_bank_name, @receiver_acc, @receiver_acc_name, @receiver_tax_code,
	@extra_info, @saxazkod, @op_code, @account_extra, @tax_payer_name, @debit_id

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @skip = 0
	SET @suffix = NULL

	SELECT @suffix = 
		CASE WHEN C.IS_RESIDENT = 0 THEN 
			CASE WHEN C.IS_JURIDICAL = 1 THEN '' ELSE ISNULL(', ' + C.PASSPORT, '') END + ISNULL(', ' + CC.DESCRIP, '') 
		ELSE 
			ISNULL(', ' + @sender_tax_code0, '')
		END
		FROM dbo.CLIENTS C (NOLOCK)
			INNER JOIN dbo.ACCOUNTS A (NOLOCK) ON A.CLIENT_NO = C.CLIENT_NO
			LEFT JOIN dbo.COUNTRIES CC (NOLOCK) ON CC.COUNTRY = CASE WHEN C.IS_JURIDICAL = 1 THEN C.COUNTRY ELSE C.PASSPORT_COUNTRY END
		WHERE A.ACC_ID = @debit_id
	
	IF @suffix IS NULL -- Not client
		SET @suffix = ISNULL(', ' + @sender_tax_code0, '')
	
	IF @suffix IS NOT NULL AND @suffix <> ''
		SET @sender_acc_name = @sender_acc_name + @suffix

	EXEC @r = impexp.on_user_before_import_docs_out_nbg
		@rec_id = @rec_id, @is_close_day = @is_close_day, 
		@portion_date = @date, @portion = @portion, @doc_num = @doc_num OUTPUT,
		@doc_date = @doc_date OUTPUT, @doc_date_in_doc = @doc_date_in_doc OUTPUT, @rec_date = @rec_date OUTPUT, 
		@amount = @amount, @descrip = @descrip OUTPUT,
		@sender_bank_code = @sender_bank_code OUTPUT, @sender_bank_name = @sender_bank_name OUTPUT,
		@sender_acc = @sender_acc OUTPUT, @sender_acc_name = @sender_acc_name OUTPUT, @sender_tax_code = @sender_tax_code OUTPUT,
		@receiver_bank_code = @receiver_bank_code OUTPUT, @receiver_bank_name = @receiver_bank_name OUTPUT, 
		@receiver_acc = @receiver_acc OUTPUT, @receiver_acc_name = @receiver_acc_name OUTPUT, @receiver_tax_code = @receiver_tax_code OUTPUT,
		@extra_info = @extra_info OUTPUT, @saxazkod = @saxazkod OUTPUT,
		@op_code = @op_code, @account_extra = @account_extra,
		@skip = @skip OUTPUT
	IF @r <> 0 OR @@ERROR <> 0 GOTO err_

	IF @skip = 0
	BEGIN
		INSERT INTO impexp.DOCS_OUT_NBG
		SELECT 
			@rec_id, 0, @doc_date, @date, @por, @old_flags,
			@doc_num % 10000 AS NDOC, ISNULL(@doc_date_in_doc, @doc_date) AS [DATE],
			@sender_bank_code AS NFA, CASE WHEN LEN (@sender_acc) <= 9 THEN REPLICATE('0',9 - LEN(@sender_acc)) + @sender_acc ELSE '' END AS NLS,
			@amount AS [SUM], 
			@receiver_bank_code AS NFB, CASE WHEN LEN (@receiver_acc) <= 9 THEN REPLICATE('0',9 - LEN(@receiver_acc)) + @receiver_acc ELSE '' END AS NLSK,
			@sender_tax_code AS GIK, @sender_acc AS NLS_AX, 
			@receiver_tax_code AS MIK, @receiver_acc AS NLSK_AX,
			@head_code3 AS BANK_A, SUBSTRING(CONVERT(char(9),@receiver_bank_code), 7, 3) AS BANK_B,
			@sender_bank_name AS GB, SUBSTRING(@sender_acc_name, 1, 60) AS G_O, 
			@receiver_bank_name AS MB, SUBSTRING(@receiver_acc_name, 1, 60) AS M_O,
			@descrip AS GD, 
			@rec_date, @saxazkod,
			@extra_info AS DAMINF,
			NULL AS ROW_ID,
			@op_code,
			@tax_payer_name
		IF @@ERROR <> 0 GOTO err_

		UPDATE dbo.OPS_0000
		SET FLAGS = 1, UID = UID + 1, REC_STATE = 25
		WHERE REC_ID = @rec_id
		IF @@ERROR <> 0 GOTO err_

		INSERT INTO dbo.DOC_CHANGES (DOC_REC_ID,[USER_ID],DESCRIP) 
		VALUES (@rec_id, @user_id, 'ÓÀÁÖÈÉÓ ÂÀÃÀÔÀÍÀ ÉÌÐÏÒÔ-ÄØÓÐÏÒÔÉÓ ÌÏÃÖËÛÉ')
		IF @@ERROR <> 0 GOTO err_

		INSERT INTO impexp.DOCS_OUT_NBG_CHANGES(DOC_REC_ID, [USER_ID], CHANGE_TYPE, DESCRIP)
		VALUES (@rec_id, @user_id, 21, 'ÓÀÁÖÈÉÓ ÜÀÔÅÉÒÈÅÀ')
		IF @@ERROR <> 0 GOTO err_
	END
	
	FETCH NEXT FROM cc
	INTO @rec_id, @doc_num, @doc_date, @doc_date_in_doc, @rec_date, @old_flags, @amount, @descrip,
		@sender_bank_code, @sender_bank_name, @sender_acc, @sender_acc_name, @sender_tax_code0, @sender_tax_code,
		@receiver_bank_code, @receiver_bank_name, @receiver_acc, @receiver_acc_name, @receiver_tax_code,
		@extra_info, @saxazkod, @op_code, @account_extra, @tax_payer_name, @debit_id
END

CLOSE cc
DEALLOCATE cc

COMMIT
RETURN @@ERROR

err_:

CLOSE cc
DEALLOCATE cc
IF @@TRANCOUNT > 0 ROLLBACK
RETURN 1
GO
