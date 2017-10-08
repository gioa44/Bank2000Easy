SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[sys_zero_val_position_dept]
	@dt smalldatetime
AS

DECLARE
	@account TACCOUNT,
	@bank_conv_account_gel TACCOUNT,
	@bank_conv_account_val TACCOUNT,
	@iso TISO,
	@saldo TAMOUNT,
	@saldo_equ TAMOUNT,
	@op_code varchar(5),
	@r int,
	@rec_id int,
	@descrip varchar(100),
	@dept_no int,
	@our_bank_code TGEOBANKCODE

SET @op_code = '*VPD*'
SET @descrip = 'ÓÀÅÀËÖÔÏ ÐÏÆÉÝÉÉÓ ÂÀÍÖËÄÁÀ(ÂÀÍÚÏ×ÉËÄÁÀ)'

SELECT @dept_no = VALS FROM dbo.INI_INT
WHERE IDS = 'BRANCH_NUM'

SELECT @our_bank_code = VALS FROM dbo.INI_INT
WHERE IDS = 'OUR_BANK_CODE'

EXEC dbo.GET_DEPT_ACC @dept_no, 'CONV_ACC_906', @bank_conv_account_gel OUTPUT
EXEC dbo.GET_DEPT_ACC @dept_no, 'CONV_ACC_906_V', @bank_conv_account_val OUTPUT

DECLARE cc_gel CURSOR LOCAL FOR
	SELECT ACCOUNT, ISO, SALDO, SALDO_EQU 
	FROM dbo.ACC_VIEW
	WHERE BAL_ACC_ALT BETWEEN 2601.00 AND 2601.99 AND ISO = 'GEL' AND
			DEPT_NO IN (SELECT DEPT_NO FROM dbo.DEPTS WHERE CODE9 = @our_bank_code AND IS_DEPT = 1)
	FOR READ ONLY

DECLARE cc_val CURSOR LOCAL FOR
	SELECT ACCOUNT, ISO, SALDO, SALDO_EQU 
	FROM dbo.ACC_VIEW
	WHERE BAL_ACC_ALT BETWEEN 2611.00 AND 2611.99 AND ISO <> 'GEL' AND
			DEPT_NO IN (SELECT DEPT_NO FROM dbo.DEPTS WHERE CODE9 = @our_bank_code AND IS_DEPT = 1)
	FOR READ ONLY

OPEN cc_gel
IF @@ERROR <> 0  GOTO RollBackThisTrans

FETCH NEXT FROM cc_gel INTO @account, @iso, @saldo, @saldo_equ
IF @@ERROR <> 0 GOTO RollBackThisTrans

WHILE @@FETCH_STATUS = 0
BEGIN

	IF @saldo > 0
	BEGIN
		INSERT INTO dbo.DOCS (DOC_DATE,ISO,AMOUNT,AMOUNT_EQU,DOC_NUM,OP_CODE,DEBIT,CREDIT,REC_STATE,DESCRIP,PARENT_REC_ID,OWNER,DOC_TYPE)
		VALUES (@dt,@iso,@saldo,@saldo_equ,2,@op_code,@bank_conv_account_gel,@account,20,@descrip,0,3,-3)
	END
	IF @saldo < 0
	BEGIN
		SET @saldo = - @saldo
		SET @saldo_equ = - @saldo_equ
		INSERT INTO dbo.DOCS (DOC_DATE,ISO,AMOUNT,AMOUNT_EQU,DOC_NUM,OP_CODE,DEBIT,CREDIT,REC_STATE,DESCRIP,PARENT_REC_ID,OWNER,DOC_TYPE)
		VALUES (@dt,@iso,@saldo,@saldo_equ,2,@op_code,@account,@bank_conv_account_gel,20,@descrip,0,3,-3)
	END

	FETCH NEXT FROM cc_gel INTO @account, @iso, @saldo, @saldo_equ
	IF @@ERROR <> 0 GOTO RollBackThisTrans

END

OPEN cc_val
IF @@ERROR <> 0  GOTO RollBackThisTrans

FETCH NEXT FROM cc_val INTO @account, @iso, @saldo, @saldo_equ
IF @@ERROR <> 0 GOTO RollBackThisTrans

WHILE @@FETCH_STATUS = 0
BEGIN
	IF @saldo > 0
	BEGIN
		INSERT INTO dbo.DOCS (DOC_DATE,ISO,AMOUNT,AMOUNT_EQU,DOC_NUM,OP_CODE,DEBIT,CREDIT,REC_STATE,DESCRIP,PARENT_REC_ID,OWNER,DOC_TYPE)
		VALUES (@dt,@iso,@saldo,@saldo_equ,2,@op_code,@bank_conv_account_val,@account,20,@descrip,0,3,-3)
	END
	IF @saldo < 0
	BEGIN
		SET @saldo = - @saldo
		SET @saldo_equ = - @saldo_equ
		INSERT INTO dbo.DOCS (DOC_DATE,ISO,AMOUNT,AMOUNT_EQU,DOC_NUM,OP_CODE,DEBIT,CREDIT,REC_STATE,DESCRIP,PARENT_REC_ID,OWNER,DOC_TYPE)
		VALUES (@dt,@iso,@saldo,@saldo_equ,2,@op_code,@account,@bank_conv_account_val,20,@descrip,0,3,-3)
	END

	FETCH NEXT FROM cc_val INTO @account, @iso, @saldo, @saldo_equ
	IF @@ERROR <> 0 GOTO RollBackThisTrans
END

PRINT 'MOVING AUTOMATIC DOCS TO ARC (dept)..'
EXEC @r = dbo._MOVE_AUTO_DOCS_TO_ARC @dt
IF @@ERROR<>0 OR @r<>0 
BEGIN 
  RAISERROR ('ÛÄÝÃÏÌÀ ÃÙÉÓ ÃÀáÖÒÅÉÓÀÓ (ÓÀÅ. ÐÏÆÉÝÉÉÓ(ÂÀÍÚ) ÀÅÔÏ. ÓÀÁÖÈÄÁÉÓ ÂÀÃÀÔÀÍÀ ÀÒØÉÅÛÉ). ÃÙÄ ÀÒ ÃÀÉáÖÒÀ',16,1)
  RETURN (111) 
END
	
RollBackThisTrans:

CLOSE cc_gel
DEALLOCATE cc_gel

CLOSE cc_val
DEALLOCATE cc_val

RETURN 0
GO
