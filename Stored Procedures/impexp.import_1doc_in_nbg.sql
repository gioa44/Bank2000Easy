SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [impexp].[import_1doc_in_nbg]
	@date smalldatetime,
	@por int,
	@user_id int,
	@row_id int
AS

SET NOCOUNT ON;

DECLARE 
	@perc1 int,
	@perc2 int,
	@check_tax_code int

EXEC dbo.GET_SETTING_INT 'IE_PERCENT_NBG1', @perc1 OUTPUT
EXEC dbo.GET_SETTING_INT 'IE_PERCENT_NBG2', @perc2 OUTPUT
EXEC dbo.GET_SETTING_INT 'IE_CHECK_TAX_CODE', @check_tax_code OUTPUT

DECLARE 
	@ndoc int,
	@bdate smalldatetime,
	@nfa int,
	@gik varchar(11),
	@nls varchar(9),
	@sum money, 
	@nfb int,
	@mik varchar(11),
	@nlsk varchar(9),
	@gb varchar(50),
	@g_o varchar(100),
	@mb varchar(50),
	@m_o varchar(100),
	@gd varchar(200),
	@nls_ax varchar(34),
	@nlsk_ax varchar(34),
	@rec_date smalldatetime,
	@saxazkod varchar(9),
	@daminf varchar(250),
	@bank_a char(3),
	@bank_b char(3),
	@account TACCOUNT

SELECT 
	@ndoc = NDOC, 
	@bdate = DATE, 
	@nfa = NFA, 
	@gik = GIK, 
	@nls = NLS, 
	@sum = [SUM], 
	@nfb = NFB, 
	@mik = MIK, 
	@nlsk = NLSK, 
	@gb = GB, 
	@g_o = G_O, 
	@mb = MB,
	@m_o = M_O, 
	@gd = SUBSTRING(GD, 1, 150), 
	@nls_ax = NLS_AX, 
	@nlsk_ax = NLSK_AX, 
	@rec_date = REC_DATE, 
	@saxazkod = SAXAZKOD, 
	@daminf = DAMINF,
	@bank_a = BANK_A,
	@bank_b = BANK_B,
	@account = ACCOUNT
FROM #nbg_in
WHERE ROW_ID = @row_id

DECLARE
	@acc_id int,
	@other_info varchar(max),
	@error_reason varchar(max),
	@doc_state int,
	@is_ready bit

SET @acc_id = NULL
	
SET @doc_state = 29 -- Bad
SET @is_ready = 0

IF NOT EXISTS(SELECT * FROM dbo.DEPTS WHERE CODE9 = @nfb)
BEGIN
	SET @error_reason = 'ÌÉÌÙÄÁÉ ÁÀÍÊÉ ÀÒ ÌÏÉÞÄÁÍÀ: ' + convert(varchar(20), @nfb)
END
ELSE
IF @account IS NULL
BEGIN
	SET @error_reason = 'ÌÉÌÙÄÁÉÓ ÀÍÂÀÒÉÛÉ ÀÒ ÛÄÄÓÀÁÀÌÄÁÀ ÓÉÂÒÞÉÈ ÁÀÍÊÉ 2000 ÀÍÂÀÒÉÛÄÁÉÓ ÓÔÀÍÃÀÒÔÓ: ' + ISNULL(@nlsk, '')
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

	SELECT TOP 1 @branch_id = A.BRANCH_ID, @acc_id = A.ACC_ID, @client_no = A.CLIENT_NO, 
		@acc_state = A.REC_STATE, @acc_type = A.ACC_TYPE, @acc_subtype = A.ACC_SUBTYPE, @acc_name_to_compare = A.DESCRIP
	FROM dbo.DEPTS D (NOLOCK)
		INNER JOIN dbo.ACCOUNTS A (NOLOCK) ON A.BRANCH_ID = D.BRANCH_ID AND A.ACCOUNT = @account AND A.ISO = 'GEL'
	WHERE D.CODE9 = @nfb AND D.IS_DEPT = 0

	IF @acc_id IS NULL
	BEGIN
		SET @error_reason = 'ÌÉÌÙÄÁÉÓ ÀÍÂÀÒÉÛÉ ÀÒ ÌÏÉÞÄÁÍÀ: ' + ISNULL(convert(varchar(20), @nfb) + ' - ' + convert(varchar(20), @account) + '/GEL' , '')
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
			IF @check_tax_code <> 0 AND @client_no IS NOT NULL AND ISNULL(@mik, '') <> ''
			BEGIN
				DECLARE 
					@tax_insp_code varchar(11),
					@personal_id varchar(20)
				
				SELECT @tax_insp_code = TAX_INSP_CODE, @personal_id = PERSONAL_ID
				FROM dbo.CLIENTS (NOLOCK)
				WHERE CLIENT_NO = @client_no

				IF @mik = @tax_insp_code OR @mik = @personal_id
					SET @doc_state = 21	-- Good
				ELSE
				BEGIN
					SET @doc_state = 25	-- Yellow
					SET @error_reason = 'ÓÀÉÃÄÍÔÉ×ÉÊÀÝÉÏ ÊÏÃÉ ÀÒ ÃÀÄÌÈáÅÀ'
				END
			END
			ELSE
				SET @doc_state = 21	-- Good

			DECLARE @percent int
			IF @client_no IS NOT NULL
				SELECT @acc_name_to_compare = DESCRIP
				FROM dbo.CLIENTS (NOLOCK)
				WHERE CLIENT_NO = @client_no

			SELECT @percent = dbo.clr_string_compare (@m_o, @acc_name_to_compare)
			IF @percent < @perc2 
			BEGIN
				SET @doc_state = 29 -- bad
				SET @error_reason = 'ÌÉÌÙÄÁÉÓ ÃÀÓÀáÄËÄÁÀ ÀÒ ÃÀÄÌÈáÅÀ'
			END
			ELSE
			IF @percent < @perc1 AND @doc_state < 25
			BEGIN
				SET @doc_state = 25 -- Yellow
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
	WHERE A.BRANCH_ID <> @branch_id AND A.ACCOUNT =  @account AND A.ISO = 'GEL' AND A.REC_STATE NOT IN (2, 128)

	IF @other_info = ''
		SET @other_info = null
END

SET @other_info = SUBSTRING(@other_info, 1, 250)

EXEC impexp.on_user_review_doc_state_in_nbg @row_id, @acc_state, @acc_type, @acc_subtype, @doc_state OUTPUT, @error_reason OUTPUT, @other_info OUTPUT

INSERT INTO impexp.DOCS_IN_NBG (
	PORTION_DATE,
	PORTION,
	ROW_ID,
	UID,
	NDOC,
	DATE,
	NFA,
	NLS,
	[SUM],
	NFB,
	NLSK,
	GIK,
	NLS_AX,
	MIK,
	NLSK_AX,
	BANK_A,
	BANK_B,
	GB,
	G_O,
	MB,
	M_O,
	GD,
	REC_DATE,
	SAXAZKOD,
	DAMINF,
	[STATE],
	IS_READY,
	ACCOUNT,
	ACC_ID,
	OTHER_INFO,
	ERROR_REASON,
	DOC_DATE,
	DOC_REC_ID
)

VALUES (
	@date,
	@por,
	@row_id,
	0, -- UID
	@ndoc, 
	@bdate,
	@nfa,
	@nls,
	@sum,
	@nfb,
	@nlsk,
	@gik,
	@nls_ax,
	@mik,
	@nlsk_ax,
	@bank_a,
	@bank_b,	
	@gb,
	@g_o,
	@mb,
	@m_o,
	@gd,
	@rec_date,
	@saxazkod,
	@daminf,
	@doc_state,
	@is_ready,
	@account,
	@acc_id,
	@other_info,
	@error_reason,
	@date,
	NULL
)
IF @@ERROR <> 0 RETURN 1

DECLARE @s varchar(255)

SET @s = 'ÓÀÁÖÈÉÓ ÃÀÉÌÐÏÒÔÄÁÀ - ' + CASE @doc_state WHEN 21 THEN 'ÊÀÒÂÀÃ' WHEN 25 THEN 'ÓÀÄàÅÏÃ' ELSE 'ÝÖÃÀÃ' END +
	': ' + ISNULL(@m_o, '')

INSERT INTO impexp.DOCS_IN_NBG_CHANGES (PORTION_DATE, PORTION, ROW_ID, [USER_ID], CHANGE_TYPE, DESCRIP)
VALUES (@date, @por, @row_id, @user_id, 21, @s)

RETURN @@ERROR
GO
