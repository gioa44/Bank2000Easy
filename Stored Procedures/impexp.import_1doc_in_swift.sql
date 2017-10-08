SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [impexp].[import_1doc_in_swift]
	@user_id int,
	@row_id int
AS

SET NOCOUNT ON;

DECLARE 
	@perc1 int,
	@perc2 int

EXEC dbo.GET_SETTING_INT 'IE_PERCENT_SWIFT1', @perc1 OUTPUT
EXEC dbo.GET_SETTING_INT 'IE_PERCENT_SWIFT2', @perc2 OUTPUT

DECLARE
	@por int,
	@ref_num varchar(32),
	@date smalldatetime,
	@iso TISO,
	@amount money,
	@descrip varchar(150),
	@sender_bank_code varchar(37),
	@sender_bank_name varchar(105),
	@sender_acc varchar(37),
	@sender_acc_name varchar(105),
	@receiver_bank_code varchar(37),
	@receiver_bank_name varchar(105),
	@receiver_acc varchar(37),
	@receiver_acc_name varchar(105),
	@intermed_bank_code varchar(37),
	@intermed_bank_name varchar(105),
	@cor_bank_code varchar(37),
	@cor_bank_name varchar(105),
	@cor_country char(2),
	@correspondent_bank_id int,
	@tag_53x_status char(1),
	@tag_53x_value varchar(37),
	@tag_54x_status char(1),
	@tag_54x_value varchar(35),
	@extra_info varchar(255),
	@extra_info_descrip bit,
	@det_of_charg char(3),
	@swift_text varchar(max),
	@account TACCOUNT,
	@doc_date smalldatetime,
	@swift_file_row_id int,
	@swift_filename varchar(100),
	@finalyze_bank_id int
SELECT 
	@ref_num = REF_NUM,
	@date = DATE,
	@iso = ISO,
	@amount = AMOUNT,
	@descrip = DESCRIP,
	@sender_bank_code = SENDER_BANK_CODE,
	@sender_bank_name = SENDER_BANK_NAME,
	@sender_acc = SENDER_ACC,
	@sender_acc_name = SENDER_ACC_NAME,
	@receiver_bank_code = RECEIVER_BANK_CODE,
	@receiver_bank_name = RECEIVER_BANK_NAME,
	@receiver_acc = RECEIVER_ACC,
	@receiver_acc_name = RECEIVER_ACC_NAME,
	@intermed_bank_code = INTERMED_BANK_CODE,
	@intermed_bank_name = INTERMED_BANK_NAME,
	@cor_bank_code = COR_BANK_CODE,
	@cor_bank_name = COR_BANK_NAME,
	@cor_country = COR_COUNTRY,
	@tag_53x_status = TAG_53X_STATUS,
	@tag_53x_value = TAG_53X_VALUE,
	@tag_54x_status = TAG_54X_STATUS,
	@tag_54x_value = TAG_54X_VALUE,

	@extra_info = EXTRA_INFO,
	@extra_info_descrip = EXTRA_INFO_DESCRIP,
	@det_of_charg = DET_OF_CHARG,
	@swift_text = SWIFT_TEXT,
	@account = ACCOUNT,
	@doc_date = DOC_DATE,
	@swift_file_row_id = SWIFT_FILE_ROW_ID,
	@swift_filename = SWIFT_FILENAME
FROM #swift_in
WHERE ROW_ID = @row_id

IF EXISTS(SELECT *
	FROM impexp.DOCS_IN_SWIFT (NOLOCK)
	WHERE REF_NUM = @ref_num AND AMOUNT = @amount AND ISO = @iso) RETURN 0

DECLARE
	@new_row_id int,
	@acc_id int,
	@other_info varchar(max),
	@error_reason varchar(max),
	@doc_state int,
	@is_ready bit

SET @acc_id = NULL

SELECT @new_row_id = MAX(ROW_ID)
FROM impexp.DOCS_IN_SWIFT

SET @new_row_id = ISNULL(@new_row_id, 0) + 1
	
SET @doc_state = 29 -- Bad
SET @is_ready = 0

IF ISNULL(@tag_54x_status, '') = 'A' AND ISNULL(@tag_54x_value, '') <> ''
	SELECT @finalyze_bank_id = REC_ID
	FROM dbo.CORRESPONDENT_BANKS
	WHERE SUBSTRING(BIC, 1, 8) = SUBSTRING(@tag_54x_value, 1, 8) AND ISO = @iso

IF @finalyze_bank_id IS NULL AND ISNULL(@tag_53x_status, '') = 'A' AND ISNULL(@tag_53x_value, '') <> ''
	SELECT @finalyze_bank_id = REC_ID
	FROM dbo.CORRESPONDENT_BANKS
	WHERE SUBSTRING(BIC, 1, 8) = SUBSTRING(@tag_53x_value, 1, 8) AND ISO = @iso

IF @finalyze_bank_id IS NULL AND ISNULL(@cor_bank_code, '') <> ''
	SELECT @finalyze_bank_id = REC_ID
	FROM dbo.CORRESPONDENT_BANKS
	WHERE SUBSTRING(BIC, 1, 8) = SUBSTRING(@cor_bank_code, 1, 8) AND ISO = @iso

IF @finalyze_bank_id IS NULL AND ISNULL(@cor_bank_code, '') = ''
	SELECT @finalyze_bank_id = REC_ID
	FROM dbo.CORRESPONDENT_BANKS
	WHERE SUBSTRING(BIC, 1, 8) = SUBSTRING(@sender_bank_code, 1, 8) AND ISO = @iso

IF (ISNULL(@receiver_bank_code, '') = '') OR (NOT EXISTS(SELECT * FROM dbo.DEPTS WHERE SUBSTRING(BIC, 1, 8) = SUBSTRING(@receiver_bank_code, 1, 8)))
BEGIN
	SET @error_reason = 'ÌÉÌÙÄÁÉ ÁÀÍÊÉ ÀÒ ÌÏÉÞÄÁÍÀ: ' + convert(varchar(20), ISNULL(@receiver_bank_code, 'N/A'))
END
ELSE
IF @account IS NULL
BEGIN
	SET @error_reason = 'ÌÉÌÙÄÁÉÓ ÀÍÂÀÒÉÛÉ ÀÒ ÛÄÄÓÀÁÀÌÄÁÀ ÓÉÂÒÞÉÈ ÁÀÍÊÉ 2000 ÀÍÂÀÒÉÛÄÁÉÓ ÓÔÀÍÃÀÒÔÓ: ' + ISNULL(@receiver_acc, '')
END
ELSE
BEGIN
	DECLARE
		@branch_id int,
		@client_no int,
		@acc_state int,
		@acc_type int,
		@acc_subtype int,
		@acc_name_to_compare varchar(100)

	IF LEN(@receiver_bank_code) = 8 OR (LEN(@receiver_bank_code) = 11 AND UPPER(SUBSTRING(@receiver_bank_code, 9, 3)) = 'XXX')
		SELECT @branch_id = A.BRANCH_ID, @acc_id = A.ACC_ID, @client_no = A.CLIENT_NO, 
			@acc_state = A.REC_STATE, @acc_type = A.ACC_TYPE, @acc_subtype = A.ACC_SUBTYPE, @acc_name_to_compare = A.DESCRIP_LAT
		FROM dbo.DEPTS D (NOLOCK)
			INNER JOIN dbo.ACCOUNTS A (NOLOCK) ON A.BRANCH_ID = D.BRANCH_ID AND A.ACCOUNT = @account AND A.ISO = @iso
		WHERE SUBSTRING(D.BIC, 1, 8) = SUBSTRING(@receiver_bank_code, 1, 8) AND D.IS_DEPT = 0
	ELSE
		SELECT @branch_id = A.BRANCH_ID, @acc_id = A.ACC_ID, @client_no = A.CLIENT_NO, 
			@acc_state = A.REC_STATE, @acc_type = A.ACC_TYPE, @acc_subtype = A.ACC_SUBTYPE, @acc_name_to_compare = A.DESCRIP_LAT
		FROM dbo.DEPTS D (NOLOCK)
			INNER JOIN dbo.ACCOUNTS A (NOLOCK) ON A.BRANCH_ID = D.BRANCH_ID AND A.ACCOUNT = @account AND A.ISO = @iso
		WHERE D.BIC = @receiver_bank_code AND D.IS_DEPT = 0

	IF @@ROWCOUNT > 1
	BEGIN
		SET @error_reason = 'ÌÉÌÙÄÁÉÓ ÀÍÂÀÒÉÛÉ ÌÄÏÒÃÄÁÀ: ' + ISNULL(convert(varchar(20), @receiver_bank_code) + ' - ' + convert(varchar(20), @receiver_acc) + '/' + @iso , '')
		SET @acc_id = NULL
	END
	ELSE
	IF @acc_id IS NULL
	BEGIN
		SET @error_reason = 'ÌÉÌÙÄÁÉÓ ÀÍÂÀÒÉÛÉ ÀÒ ÌÏÉÞÄÁÍÀ: ' + ISNULL(convert(varchar(20), @receiver_bank_code) + ' - ' + convert(varchar(20), @receiver_acc) + '/' + @iso , '')
	END
	ELSE
	BEGIN
		IF @acc_state IN (2, 16, 64, 128)
		BEGIN
			SET @error_reason = 'ÌÉÌÙÄÁÉÓ ÀÍÂÀÒÉÛÆÄ ÈÀÍáÉÓ ÜÀÒÉÝáÅÀ ÀÒ ÛÄÉÞËÄÁÀ (ÓÔÀÔÖÓÉ)'
			SET @acc_id = NULL
		END
		ELSE
		IF NOT @acc_type IN (1, 32, 100, 200)
		BEGIN
			SET @error_reason = 'ÌÉÌÙÄÁÉÓ ÀÍÂÀÒÉÛÆÄ ÈÀÍáÉÓ ÜÀÒÉÝáÅÀ ÀÒ ÛÄÉÞËÄÁÀ (ÔÉÐÉ)'
			SET @acc_id = NULL
		END
		ELSE
		BEGIN
			SET @doc_state = 21	-- Good

			DECLARE @percent int
			IF @client_no IS NOT NULL
				SELECT @acc_name_to_compare = DESCRIP_LAT
				FROM dbo.CLIENTS (NOLOCK)
				WHERE CLIENT_NO = @client_no

			SELECT @percent = dbo.clr_string_compare (@receiver_acc_name, @acc_name_to_compare)
			IF @percent < @perc2
			BEGIN
				SET @doc_state = 29
				SET @error_reason = 'ÌÉÌÙÄÁÉÓ ÃÀÓÀáÄËÄÁÀ ÀÒ ÃÀÄÌÈáÅÀ'
			END
			ELSE
			IF @percent < @perc1 AND @doc_state < 25
			BEGIN
				SET @doc_state = 25
				SET @error_reason = 'ÌÉÌÙÄÁÉÓ ÃÀÓÀáÄËÄÁÀ ÃÀÄÌÈáÅÀ ÍÀßÉËÏÁÒÉÅ'
			END
		END
	END
	
	SET @other_info = ''
	SELECT @other_info = @other_info + 
		DP.ALIAS + ': ' + A.DESCRIP + ' - (' + ISNULL(AT.DESCRIP + ' ' + ISNULL(AST.DESCRIP,''), '') + ')' + char(13)
	FROM dbo.ACCOUNTS A
		LEFT JOIN dbo.DEPTS DP (NOLOCK) ON DP.DEPT_NO = A.DEPT_NO
		LEFT JOIN dbo.ACC_TYPES AT (NOLOCK) ON AT.ACC_TYPE = A.ACC_TYPE
		LEFT JOIN dbo.ACC_SUBTYPES AST (NOLOCK) ON AST.ACC_TYPE = A.ACC_TYPE AND AST.ACC_SUBTYPE = A.ACC_SUBTYPE
	WHERE A.BRANCH_ID <> @branch_id AND A.ACCOUNT = @account AND A.ISO = @iso AND A.REC_STATE NOT IN (2, 128)

	IF @other_info = ''
		SET @other_info = null
END

SET @other_info = SUBSTRING (@other_info, 1, 250)

SET @por = impexp.get_portion_in_swift(@iso, @finalyze_bank_id)

EXEC impexp.on_user_review_doc_state_in_swift @row_id, @acc_state, @acc_type,	@acc_subtype, @doc_state OUTPUT, @error_reason OUTPUT, @other_info OUTPUT

INSERT INTO impexp.DOCS_IN_SWIFT (
	PORTION_DATE,
	PORTION,
	ROW_ID,
	REF_NUM,
	DATE,
	ISO,
	AMOUNT,
	DESCRIP,
	SENDER_BANK_CODE,
	SENDER_BANK_NAME,
	SENDER_ACC,
	SENDER_ACC_NAME,
	RECEIVER_BANK_CODE,
	RECEIVER_BANK_NAME,
	RECEIVER_ACC,
	RECEIVER_ACC_NAME,
	INTERMED_BANK_CODE,
	INTERMED_BANK_NAME,
	COR_BANK_CODE,
	COR_BANK_NAME,
	COR_COUNTRY,
	CORRESPONDENT_BANK_ID,
	TAG_53X_STATUS,
	TAG_53X_VALUE,
	TAG_54X_STATUS,
	TAG_54X_VALUE,
	EXTRA_INFO,
	EXTRA_INFO_DESCRIP,
	DET_OF_CHARG,
	SWIFT_TEXT,
	[STATE],
	IS_READY,
	ACCOUNT,
	ACC_ID,
	OTHER_INFO,
	ERROR_REASON,
	DOC_DATE,
	SWIFT_FILE_ROW_ID,
	SWIFT_FILENAME,
	FINALYZE_BANK_ID,
	DOC_REC_ID
)
VALUES (
	@doc_date,
	@por,
	@new_row_id,
	@ref_num,
	@date,
	@iso,
	@amount,
	@descrip,
	@sender_bank_code,
	@sender_bank_name,
	@sender_acc,
	@sender_acc_name,
	@receiver_bank_code,
	@receiver_bank_name,
	@receiver_acc,
	@receiver_acc_name,
	@intermed_bank_code,
	@intermed_bank_name,
	@cor_bank_code,
	@cor_bank_name,
	@cor_country,
	@correspondent_bank_id,
	@tag_53x_status,
	@tag_53x_value,
	@tag_54x_status,
	@tag_54x_value,
	@extra_info,
	@extra_info_descrip,
	@det_of_charg,
	@swift_text,
	@doc_state,
	@is_ready,
	@account,
	@acc_id,
	@other_info,
	@error_reason,
	@date,
	@swift_file_row_id,
	@swift_filename,
	@finalyze_bank_id,
	NULL
)

DECLARE @s varchar(255)

SET @s = 'ÓÀÁÖÈÉÓ ÃÀÉÌÐÏÒÔÄÁÀ - ' + CASE @doc_state WHEN 21 THEN 'ÊÀÒÂÀÃ' WHEN 25 THEN 'ÓÀÄàÅÏÃ' ELSE 'ÝÖÃÀÃ' END +
	': ' + ISNULL(@receiver_acc_name, '')

INSERT INTO impexp.DOCS_IN_SWIFT_CHANGES (PORTION_DATE, PORTION, ROW_ID, [USER_ID], CHANGE_TYPE, DESCRIP)
VALUES (@doc_date, @por, @new_row_id, @user_id, 21, @s)

RETURN @@ERROR
GO
