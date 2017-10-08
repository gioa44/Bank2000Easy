SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ADD_INCASSO_DOC]
	@rec_id int OUTPUT,
	@incasso_id int,
	@user_id int,
	@doc_date smalldatetime,
	@amount money,
	@aut_level int,
	@lat bit = 0
AS
SET NOCOUNT ON

DECLARE
	@r int,
	@sender_bank_code TGEOBANKCODE,
	@sender_bank_name varchar(100),
	@doc_type tinyint,

	@descrip varchar(150),
	@extra_info varchar(250),
	@recv_tax_code varchar(11),
	@recv_bank_code TINTBANKCODE,
	@recv_bank_name varchar(100),
	@recv_acc TINTACCOUNT,
	@recv_acc_name varchar(100),
	@sender_acc TINTACCOUNT,
	@sender_acc_id int,
	@sender_acc_name varchar(100),
	@sender_tax_code varchar(11),
	@credit TACCOUNT,
	@is_branch bit,

	@treasury_code varchar(9),

	@plat_inner tinyint,
	@plat_outer  tinyint,
	@plat_outer_branch  tinyint,
	@doc_num int,
	@balance money,
	@incasso_num varchar(20),
	@issue_date smalldatetime,

	@credit_id int

SET NOCOUNT ON

SET @doc_date = convert(smalldatetime,floor(convert(real,@doc_date)))

SELECT	@sender_acc_id = ACC_ID, @recv_bank_code = RECEIVER_BANK_CODE, @recv_bank_name = RECEIVER_BANK_NAME,
		@recv_acc = RECEIVER_ACC, @recv_acc_name = RECEIVER_ACC_NAME, @recv_tax_code = RECEIVER_TAX_CODE, @treasury_code = SAXAZKOD,
		@descrip = DESCRIP, @doc_num = ISNULL(PAYED_COUNT, 0) + 1, @balance = BALANCE, @issue_date=ISSUE_DATE, @incasso_num=INCASSO_NUM
FROM	dbo.INCASSO (NOLOCK)
WHERE	REC_ID = @incasso_id

SET @balance = @balance - @amount

IF @balance = $0.00
	SET @extra_info = 'ÓÒÖËÉ ÃÀ×ÀÒÅÀ, ÒÉÂÉÈÉ # '
ELSE
	SET @extra_info = 'ÍÀßÉËÏÁÒÉÅÉ ÃÀ×ÀÒÅÀ, ÒÉÂÉÈÉ # '

SET @extra_info = @extra_info + CONVERT(varchar(5), @doc_num) + ', ÉÍÊÀÓÏ # ' + @incasso_num + ', ' + CONVERT(varchar(10), @issue_date, 103) + ', ÂÀÍÀÙÃÄÁÖËÉ ÈÀÍáÀ: ' + CONVERT(varchar(20), @amount) + ', ÃÀÒÜÄÍÉËÉ ÍÀÛÈÉ: ' + CONVERT(varchar(15), @balance)

SELECT @sender_acc = ACCOUNT, @sender_acc_name = DESCRIP
FROM dbo.ACCOUNTS (NOLOCK)
WHERE ACC_ID = @sender_acc_id

SET @sender_bank_code = dbo.acc_get_bank_code(@sender_acc_id)

SELECT TOP 1 @sender_bank_name = DESCRIP
FROM dbo.DEPTS (NOLOCK)
WHERE CODE9 = @sender_bank_code AND IS_DEPT = 0
ORDER BY DEPT_NO


SELECT @sender_tax_code = CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END
FROM dbo.ACCOUNTS A (NOLOCK) 
	LEFT OUTER JOIN dbo.CLIENTS C(NOLOCK) ON A.CLIENT_NO = C.CLIENT_NO
WHERE A.ACC_ID = @sender_acc_id

SET @is_branch = dbo.bank_is_geo_bank_in_our_db(@recv_bank_code)

IF @is_branch <> 0 /* internal transfer */
BEGIN
	SET @doc_type = 100

	SELECT TOP 1 @credit_id = A.ACC_ID
	FROM dbo.ACCOUNTS A
		INNER JOIN dbo.DEPTS D ON D.BRANCH_ID = A.BRANCH_ID
	WHERE D.CODE9 = @recv_bank_code AND D.IS_DEPT = 0 AND A.ACCOUNT = @recv_acc AND A.ISO = 'GEL'
	ORDER BY D.DEPT_NO
END
ELSE
BEGIN
	SET @doc_type = 102

	DECLARE @corr_acc TACCOUNT
	EXEC dbo.GET_SETTING_ACC 'CORR_ACC_NA', @corr_acc OUTPUT

	SET @credit_id = dbo.acc_get_acc_id (dbo.bank_head_branch_id(), @corr_acc, 'GEL')
END

DECLARE 
	@internal_transaction bit

SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

EXEC @r = dbo.ADD_DOC4
	@rec_id = @rec_id OUTPUT,
	@user_id = @user_id,
	@doc_date = @doc_date,
	@doc_date_in_doc = @doc_date,
	@iso = 'GEL',
	@amount = @amount,
	@doc_type = @doc_type,
	@doc_num = @doc_num,
	@op_code = '*INK',
	@debit_id = @sender_acc_id,
	@sender_bank_code = @sender_bank_code,
	@sender_bank_name = @sender_bank_name,
	@sender_acc = @sender_acc,
	@sender_acc_name = @sender_acc_name,
	@sender_tax_code = @sender_tax_code,
	@credit_id = @credit_id,
	@receiver_bank_code = @recv_bank_code, 
	@receiver_bank_name = @recv_bank_name,
	@receiver_acc = @recv_acc, 
	@receiver_acc_name = @recv_acc_name, 
	@receiver_tax_code = @recv_tax_code,
	@rec_state=@aut_level,
	@parent_rec_id = 0,
	@saxazkod = @treasury_code,
	@descrip = @descrip,
	@extra_info = @extra_info,
	@flags = 0x3003C4,
	@lat = @lat,
	@add_tariff = 0,
	@check_saldo = 0

IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 4 END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN 0
GO
