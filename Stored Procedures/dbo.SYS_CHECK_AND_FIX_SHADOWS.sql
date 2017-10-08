SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[SYS_CHECK_AND_FIX_SHADOWS] 
	@only_check bit = 1
AS

 
SET NOCOUNT ON

PRINT 'CHECKING ACCOUNTS_DETAILS TABLE FOR PROBLEMS..'

BEGIN TRAN

	DECLARE @open_date smalldatetime
	SET @open_date = dbo.bank_open_date()
	 
DECLARE @acc_details TABLE (ACC_ID int NOT NULL PRIMARY KEY CLUSTERED, SHADOW_DBO money, SHADOW_CRO money, SALDO money)

INSERT INTO @acc_details (ACC_ID, SALDO)
SELECT A.ACC_ID, dbo.acc_get_balance (A.ACC_ID, @open_date, 1, 0, -1)
FROM dbo.ACCOUNTS A

DECLARE 
  @amount TAMOUNT,
  @debit int,
  @credit int,
  @doc_date smalldatetime,
  @rec_state tinyint
 

DECLARE cur CURSOR
READ_ONLY
FOR 
SELECT AMOUNT, DEBIT_ID, CREDIT_ID, DOC_DATE, REC_STATE
FROM dbo.OPS_0000 (TABLOCK)
 
OPEN cur
 
FETCH NEXT FROM cur INTO @amount, @debit, @credit, @doc_date, @rec_state
 
WHILE (@@fetch_status <> -1)
BEGIN
 
  DECLARE @act_pas tinyint
  SELECT @act_pas = ACT_PAS FROM dbo.ACCOUNTS WHERE ACC_ID = @debit
 
  IF (@act_pas <> 2) OR (@rec_state >= 10)
  BEGIN
    UPDATE @acc_details
    SET SHADOW_DBO = ISNULL(SHADOW_DBO,0) + @amount
    WHERE ACC_ID = @debit
    IF @@ERROR <> 0 RETURN(1)
  END
 
  SELECT @act_pas = ACT_PAS FROM dbo.ACCOUNTS WHERE ACC_ID = @credit
  IF (@act_pas = 2) OR (@rec_state >= 10)
  BEGIN
    UPDATE @acc_details
    SET SHADOW_CRO = ISNULL(SHADOW_CRO,0) + @amount
    WHERE ACC_ID = @credit
    IF @@ERROR <> 0 RETURN(2)
  END
 
  FETCH NEXT FROM cur INTO @amount, @debit, @credit, @doc_date, @rec_state
END
 
CLOSE cur
DEALLOCATE cur

DECLARE @count int

SELECT A.ACC_ID, 
	AD.SHADOW_DBO AS SHADOW_DBO_IN_DB, A.SHADOW_DBO AS SHADOW_DBO_REAL, 
	AD.SHADOW_CRO AS SHADOW_CRO_IN_DB, A.SHADOW_CRO AS SHADOW_CRO_REAL, 
	AD.SALDO AS SALDO_IN_DB, A.SALDO AS SALDO_REAL
FROM @acc_details A
	LEFT JOIN dbo.ACCOUNTS_DETAILS AD ON AD.ACC_ID = A.ACC_ID
WHERE AD.SHADOW_DBO <> A.SHADOW_DBO OR AD.SHADOW_CRO <> A.SHADOW_CRO OR AD.SALDO <> A.SALDO
 
SET @count = @@ROWCOUNT 
IF @count > 0
	PRINT '  ERRORS FOUND!'

IF @count > 0
BEGIN
	IF @only_check = 1
		PRINT 'EXECUTE "dbo.SYS_CHECK_AND_FIX_SHADOWS @only_check = 0" TO FIX THESE ERRORS'
	ELSE
	BEGIN
		PRINT 'REPAIRING ACCOUNTS_DETAILS TABLE'
		
		UPDATE dbo.ACCOUNTS_DETAILS
		SET UID2 = UID2 + 1, SHADOW_DBO = B.SHADOW_DBO, SHADOW_CRO = B.SHADOW_CRO, SALDO = B.SALDO
		FROM dbo.ACCOUNTS_DETAILS A
			INNER JOIN @acc_details B ON B.ACC_ID = A.ACC_ID
	END
END
ELSE
	PRINT 'NO PROBLEMS FOUND'

COMMIT
 
RETURN(0)
GO
