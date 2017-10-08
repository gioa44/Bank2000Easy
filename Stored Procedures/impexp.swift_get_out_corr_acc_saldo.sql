SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[swift_get_out_corr_acc_saldo]
	@date smalldatetime
AS

DECLARE
	@corr_account_va TACCOUNT,
	@corr_account_va2 TACCOUNT,
	@corr_account_vp TACCOUNT,
	@corr_account_vp2 TACCOUNT,
	@head_branch_id int

EXEC dbo.GET_SETTING_ACC 'CORR_ACC_VA', @corr_account_va OUTPUT
IF ISNULL(@corr_account_va, 0) = 0
	RAISERROR ('ÐÀÒÀÌÄÔÒÉ "ÓÀÊÏÒ. ÀÍÂÀÒÉÛÉ (ÅÀËÖÔÀ, ÂÀÃÀÒÉÝáÅÀ)" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ ÓÉÓÔÄÌÉÓ ÊÏÍ×ÉÂÖÒÀÝÉÀÛÉ.', 16, 1)

EXEC dbo.GET_SETTING_ACC 'CORR_ACC_VA2', @corr_account_va2 OUTPUT
IF @corr_account_va2 = 0
	SET @corr_account_va2 = NULL

EXEC dbo.GET_SETTING_ACC 'CORR_ACC_VP', @corr_account_vp OUTPUT
IF ISNULL(@corr_account_vp, 0) = 0
	RAISERROR ('ÐÀÒÀÌÄÔÒÉ "ÓÀÊÏÒ. ÀÍÂÀÒÉÛÉ (ÅÀËÖÔÀ, ÜÀÒÉÝáÅÀ)" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ ÓÉÓÔÄÌÉÓ ÊÏÍ×ÉÂÖÒÀÝÉÀÛÉ.', 16, 1)

EXEC dbo.GET_SETTING_ACC 'CORR_ACC_VP2', @corr_account_vp2 OUTPUT
IF @corr_account_vp2 = 0
	SET @corr_account_vp2 = NULL

IF @corr_account_va  = @corr_account_vp
	RAISERROR ('ÐÀÒÀÌÄÔÒÉ "ÓÀÊÏÒ. ÀÍÂÀÒÉÛÉ (ÅÀËÖÔÀ, ÜÀÒÉÝáÅÀ)" ÃÀ "ÓÀÊÏÒ. ÀÍÂÀÒÉÛÉ (ÅÀËÖÔÀ, ÂÀÃÀÒÉÝáÅÀ)" ÀÒÉÓ ÄÒÈÉÃÀÉÂÉÅÄ.', 16, 1)

SET @head_branch_id = dbo.bank_head_branch_id()

DECLARE
	@acc_id int,
	@iso TISO

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

DECLARE c CURSOR 
FOR SELECT ACC_ID, ISO 
FROM dbo.ACCOUNTS (NOLOCK)
WHERE ACCOUNT = @corr_account_va AND ISO <> 'GEL' AND REC_STATE NOT IN (2, 128) AND BRANCH_ID = @head_branch_id

OPEN c

FETCH NEXT FROM c
INTO @acc_id, @iso

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @corr_acc_saldo = -ISNULL(dbo.acc_get_balance(@acc_id, @date, default, default, 0), $0.00)

	SELECT @out_docs_saldo = ISNULL(SUM(AMOUNT), $0.00)
	FROM impexp.DOCS_OUT_SWIFT (NOLOCK)
	WHERE FINALYZE_DOC_REC_ID IS NULL AND ISO = @iso

	SELECT @queue_docs_saldo = ISNULL(SUM(D.AMOUNT), $0.00)
	FROM dbo.OPS_0000 D (NOLOCK)
		INNER JOIN dbo.DOC_DETAILS_VALPLAT DD(NOLOCK) ON D.REC_ID = DD.DOC_REC_ID
		INNER JOIN dbo.ACCOUNTS A(NOLOCK) ON A.ACC_ID = D.CREDIT_ID
	WHERE A.BRANCH_ID = @head_branch_id AND (A.ACCOUNT = @corr_account_va OR (@corr_account_va2 IS NOT NULL AND A.ACCOUNT = @corr_account_va2)) AND D.ISO = @iso AND A.ISO = D.ISO AND
		D.DOC_DATE <= @date AND D.DOC_TYPE IN (112,116) AND (D.REC_STATE < 25) AND 
		NOT EXISTS (SELECT * FROM impexp.DOCS_OUT_SWIFT A WHERE A.DOC_REC_ID = D.REC_ID)

	SELECT @bad_docs_saldo = ISNULL(SUM(D.AMOUNT), $0.00)
	FROM dbo.OPS_0000 D (NOLOCK)
		INNER JOIN dbo.DOC_DETAILS_VALPLAT DD(NOLOCK) ON D.REC_ID = DD.DOC_REC_ID
		INNER JOIN dbo.ACCOUNTS A(NOLOCK) ON A.ACC_ID = D.CREDIT_ID
	WHERE A.BRANCH_ID = @head_branch_id AND (A.ACCOUNT = @corr_account_va OR (@corr_account_va2 IS NOT NULL AND A.ACCOUNT = @corr_account_va2)) AND D.ISO = @iso AND A.ISO = D.ISO AND
		D.DOC_DATE <= @date AND D.DOC_TYPE NOT IN (112,116)

	SET @balance = @corr_acc_saldo - @out_docs_saldo - @queue_docs_saldo

	INSERT INTO @T(ACC_ID, ACCOUNT, ISO, ACCOUNT_SALDO,	OUT_DOCS_SALDO, QUEUE_DOCS_SALDO, BALANCE, BAD_DOCS_SALDO)
	VALUES(@acc_id, @corr_account_va, @iso, @corr_acc_saldo, @out_docs_saldo, @queue_docs_saldo, @balance, @bad_docs_saldo)

	FETCH NEXT FROM c
	INTO @acc_id, @iso
END

CLOSE c
DEALLOCATE c

SELECT * FROM @T
GO
