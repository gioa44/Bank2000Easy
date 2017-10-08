SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[sys_zero_val_position]
	@dt smalldatetime
AS

DECLARE
	@account TACCOUNT,
	@bank_corr_account_na TACCOUNT,
	@bank_corr_account_np TACCOUNT,
	@bank_corr_account_va TACCOUNT,
	@bank_corr_account_vp TACCOUNT,
	@iso TISO,
	@saldo TAMOUNT,
	@saldo_equ TAMOUNT,
	@op_code varchar(5),
	@r int,
	@rec_id int,
	@descrip varchar(100)
	

SET @op_code = '*VPB*'
SET @descrip = 'ÓÀÅÀËÖÔÏ ÐÏÆÉÝÉÉÓ ÂÀÍÖËÄÁÀ'

EXEC dbo.GET_SETTING_ACC 'CORR_ACC_NA', @bank_corr_account_na OUTPUT
EXEC dbo.GET_SETTING_ACC 'CORR_ACC_NP', @bank_corr_account_np OUTPUT

EXEC dbo.GET_SETTING_ACC 'CORR_ACC_VA', @bank_corr_account_va OUTPUT
EXEC dbo.GET_SETTING_ACC 'CORR_ACC_VP', @bank_corr_account_vp OUTPUT

DECLARE cc_gel CURSOR LOCAL FOR
	SELECT ACCOUNT, ISO, SALDO, SALDO_EQU 
	FROM dbo.ACC_VIEW 
	WHERE BAL_ACC_ALT BETWEEN 2601.00 AND 2601.99 AND ISO = 'GEL'
	FOR READ ONLY

DECLARE cc_val CURSOR LOCAL FOR
	SELECT ACCOUNT, ISO, SALDO, SALDO_EQU
	FROM dbo.ACC_VIEW 
	WHERE BAL_ACC_ALT BETWEEN 2611.00 AND 2611.99 AND ISO <> 'GEL'
	FOR READ ONLY

OPEN cc_gel
IF @@ERROR <> 0  GOTO RollBackThisTrans1

FETCH NEXT FROM cc_gel INTO @account, @iso, @saldo, @saldo_equ
IF @@ERROR <> 0 GOTO RollBackThisTrans1

WHILE @@FETCH_STATUS = 0
BEGIN
	IF @saldo > 0
	BEGIN
		INSERT INTO dbo.DOCS (DOC_DATE,ISO,AMOUNT,AMOUNT_EQU,DOC_NUM,OP_CODE,DEBIT,CREDIT,REC_STATE,DESCRIP,PARENT_REC_ID,OWNER,DOC_TYPE)
		VALUES (@dt,@iso,@saldo,@saldo_equ,2,@op_code,@bank_corr_account_na,@account,20,@descrip,0,3,11)
		IF @@ERROR <> 0 GOTO RollBackThisTrans1

		INSERT INTO dbo.VAL_POSITION_DOCS (DOC_DATE, AMOUNT, ISO)
		VALUES (@dt, @saldo, @iso)
		IF @@ERROR <> 0 GOTO RollBackThisTrans1
  	END
	IF @saldo < 0
	BEGIN
		SET @saldo = - @saldo
		SET @saldo_equ = - @saldo_equ

		INSERT INTO dbo.DOCS (DOC_DATE,ISO,AMOUNT,AMOUNT_EQU,DOC_NUM,OP_CODE,DEBIT,CREDIT,REC_STATE,DESCRIP,PARENT_REC_ID,OWNER,DOC_TYPE)
		VALUES (@dt,@iso,@saldo,@saldo_equ,2,@op_code,@account,@bank_corr_account_np,20,@descrip,0,3,11)
		IF @@ERROR <> 0 GOTO RollBackThisTrans1

		INSERT INTO dbo.VAL_POSITION_DOCS (DOC_DATE, AMOUNT, ISO)
		VALUES (@dt, -@saldo, @iso)
		IF @@ERROR <> 0 GOTO RollBackThisTrans1
	END

	FETCH NEXT FROM cc_gel INTO @account, @iso, @saldo, @saldo_equ
	IF @@ERROR <> 0 GOTO RollBackThisTrans1
END

RollBackThisTrans1:

CLOSE cc_gel
DEALLOCATE cc_gel

OPEN cc_val
IF @@ERROR <> 0  GOTO RollBackThisTrans2

FETCH NEXT FROM cc_val INTO @account, @iso, @saldo, @saldo_equ
IF @@ERROR <> 0 GOTO RollBackThisTrans2

WHILE @@FETCH_STATUS = 0
BEGIN
	IF @saldo > 0
	BEGIN
		INSERT INTO dbo.DOCS (DOC_DATE,ISO,AMOUNT,AMOUNT_EQU,DOC_NUM,OP_CODE,DEBIT,CREDIT,REC_STATE,DESCRIP,PARENT_REC_ID,OWNER,DOC_TYPE)
		VALUES (@dt,@iso,@saldo,@saldo_equ,2,@op_code,@bank_corr_account_va,@account,20,@descrip,0,3,11)
  		IF @@ERROR <> 0 GOTO RollBackThisTrans1

		INSERT INTO dbo.VAL_POSITION_DOCS (DOC_DATE, AMOUNT, ISO)
		VALUES (@dt, @saldo, @iso)
		IF @@ERROR <> 0 GOTO RollBackThisTrans1
	END
	IF @saldo < 0
	BEGIN
		SET @saldo = - @saldo
		SET @saldo_equ = - @saldo_equ
		INSERT INTO dbo.DOCS (DOC_DATE,ISO,AMOUNT,AMOUNT_EQU,DOC_NUM,OP_CODE,DEBIT,CREDIT,REC_STATE,DESCRIP,PARENT_REC_ID,OWNER,DOC_TYPE)
		VALUES (@dt,@iso,@saldo,@saldo_equ,2,@op_code,@account,@bank_corr_account_vp,20,@descrip,0,3,11)
		IF @@ERROR <> 0 GOTO RollBackThisTrans1

		INSERT INTO dbo.VAL_POSITION_DOCS (DOC_DATE, AMOUNT, ISO)
		VALUES (@dt, @saldo, @iso)
		IF @@ERROR <> 0 GOTO RollBackThisTrans1
	END

	FETCH NEXT FROM cc_val INTO @account, @iso, @saldo, @saldo_equ
	IF @@ERROR <> 0 GOTO RollBackThisTrans2
END


INSERT INTO dbo.DOCS_ARC (REC_ID,DOC_DATE,DOC_DATE_IN_DOC,ISO,AMOUNT,AMOUNT_EQU,DOC_NUM,OP_CODE,DEBIT,CREDIT,REC_STATE,BNK_CLI_ID,DESCRIP,PARENT_REC_ID,OWNER,DOC_TYPE,ACCOUNT_EXTRA,PROD_ID,FOREIGN_ID,CHANNEL_ID,DEPT_NO)
SELECT REC_ID,DOC_DATE,DOC_DATE_IN_DOC,ISO,AMOUNT,AMOUNT_EQU,DOC_NUM,OP_CODE,DEBIT,CREDIT,REC_STATE,BNK_CLI_ID,DESCRIP,PARENT_REC_ID,OWNER,DOC_TYPE,ACCOUNT_EXTRA,PROD_ID,FOREIGN_ID,CHANNEL_ID,DEPT_NO
FROM DOCS (TABLOCKX,UPDLOCK)WHERE DOC_TYPE = 11 AND DOC_DATE = @dt
IF @@ERROR <> 0 RETURN (1)

/* DELETES FROM DOCS */

DELETE FROM DOCS
WHERE DOC_TYPE = 11 AND DOC_DATE = @dt
IF @@ERROR <> 0 RETURN (2)


RollBackThisTrans2:

CLOSE cc_val
DEALLOCATE cc_val

RETURN 0
GO
