SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[nbg_get_out_corr_acc_saldo]
	@date smalldatetime
AS

DECLARE
	@corr_account_na TACCOUNT,
	@corr_account_na2 TACCOUNT,
	@corr_account_np TACCOUNT,
	@corr_account_np2 TACCOUNT,
	@head_branch_id int

EXEC dbo.GET_SETTING_ACC 'CORR_ACC_NA', @corr_account_na OUTPUT
IF ISNULL(@corr_account_na, 0) = 0
	RAISERROR ('ÐÀÒÀÌÄÔÒÉ "ÓÀÊÏÒ. ÀÍÂÀÒÉÛÉ (ÅÀËÖÔÀ, ÂÀÃÀÒÉÝáÅÀ)" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ ÓÉÓÔÄÌÉÓ ÊÏÍ×ÉÂÖÒÀÝÉÀÛÉ.', 16, 1)

EXEC dbo.GET_SETTING_ACC 'CORR_ACC_NA2', @corr_account_na2 OUTPUT
IF @corr_account_na2 = 0
	SET @corr_account_na2 = NULL

EXEC dbo.GET_SETTING_ACC 'CORR_ACC_NP', @corr_account_np OUTPUT
IF ISNULL(@corr_account_np, 0) = 0
	RAISERROR ('ÐÀÒÀÌÄÔÒÉ "ÓÀÊÏÒ. ÀÍÂÀÒÉÛÉ (ÅÀËÖÔÀ, ÜÀÒÉÝáÅÀ)" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ ÓÉÓÔÄÌÉÓ ÊÏÍ×ÉÂÖÒÀÝÉÀÛÉ.', 16, 1)

EXEC dbo.GET_SETTING_ACC 'CORR_ACC_NP2', @corr_account_np2 OUTPUT
IF @corr_account_np2 = 0
	SET @corr_account_np2 = NULL

IF @corr_account_na  = @corr_account_np
	RAISERROR ('ÐÀÒÀÌÄÔÒÉ "ÓÀÊÏÒ. ÀÍÂÀÒÉÛÉ (ÅÀËÖÔÀ, ÜÀÒÉÝáÅÀ)" ÃÀ "ÓÀÊÏÒ. ÀÍÂÀÒÉÛÉ (ÅÀËÖÔÀ, ÂÀÃÀÒÉÝáÅÀ)" ÀÒÉÓ ÄÒÈÉÃÀÉÂÉÅÄ.', 16, 1)

SET @head_branch_id = dbo.bank_head_branch_id()

DECLARE
	@acc_id int

DECLARE
	@corr_acc_saldo money,
	@out_docs_saldo money,
	@queue_docs_saldo money,
	@balance money,
	@bad_docs_saldo money

DECLARE
	@T TABLE (ACC_ID int NOT NULL PRIMARY KEY,
		ACCOUNT decimal(15,0) NOT NULL,
		ISO char(3) NOT NULL,
		ACCOUNT_SALDO money NOT NULL,
		OUT_DOCS_SALDO money NOT NULL,
		QUEUE_DOCS_SALDO money NOT NULL,
		BALANCE money NOT NULL,
		BAD_DOCS_SALDO money NOT NULL)


SET @acc_id = dbo.acc_get_acc_id (@head_branch_id, @corr_account_na, 'GEL')

SET @corr_acc_saldo = -ISNULL(dbo.acc_get_balance(@acc_id, @date, default, default, 0), $0.00)

SELECT @out_docs_saldo = ISNULL(SUM(AMOUNT), $0.00)
FROM impexp.PORTIONS_OUT_NBG (NOLOCK)
WHERE [STATE] <> 4

SELECT @queue_docs_saldo = ISNULL(SUM(D.AMOUNT), $0.00)
FROM dbo.OPS_0000 D (NOLOCK)
	INNER JOIN dbo.DOC_DETAILS_PLAT DD(NOLOCK) ON D.REC_ID = DD.DOC_REC_ID
	INNER JOIN dbo.ACCOUNTS A(NOLOCK) ON A.ACC_ID = D.CREDIT_ID
WHERE A.BRANCH_ID = @head_branch_id AND (A.ACCOUNT = @corr_account_na OR (@corr_account_na2 IS NOT NULL AND A.ACCOUNT = @corr_account_na2)) AND D.ISO = 'GEL' AND A.ISO = D.ISO AND
	D.DOC_DATE <= @date AND D.DOC_TYPE IN (102,106) AND (D.REC_STATE IN (0, 10, 12, 20)) AND 
	NOT EXISTS (SELECT * FROM impexp.DOCS_OUT_NBG A WHERE A.DOC_REC_ID = D.REC_ID)

SELECT @bad_docs_saldo = ISNULL(SUM(D.AMOUNT), $0.00)
FROM dbo.OPS_0000 D (NOLOCK)
	INNER JOIN dbo.DOC_DETAILS_PLAT DD(NOLOCK) ON D.REC_ID = DD.DOC_REC_ID
	INNER JOIN dbo.ACCOUNTS A(NOLOCK) ON A.ACC_ID = D.CREDIT_ID
WHERE A.BRANCH_ID = @head_branch_id AND (A.ACCOUNT = @corr_account_na OR (@corr_account_na2 IS NOT NULL AND A.ACCOUNT = @corr_account_na2)) AND D.ISO = 'GEL' AND A.ISO = D.ISO AND
	D.DOC_DATE <= @date AND D.DOC_TYPE NOT IN (102,106)

SET @balance = @corr_acc_saldo - @out_docs_saldo - @queue_docs_saldo

INSERT INTO @T(ACC_ID, ACCOUNT, ISO, ACCOUNT_SALDO,	OUT_DOCS_SALDO, QUEUE_DOCS_SALDO, BALANCE, BAD_DOCS_SALDO)
VALUES(@acc_id, @corr_account_na, 'GEL', @corr_acc_saldo, @out_docs_saldo, @queue_docs_saldo, @balance, @bad_docs_saldo)

SELECT * FROM @T
GO
