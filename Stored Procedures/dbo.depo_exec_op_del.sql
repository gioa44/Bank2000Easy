SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_exec_op_del]
	@oid int,
	@user_id int
AS

SET NOCOUNT ON

DECLARE
	@did int, 
	@st int,
	@op_type int,
	@docs_rec_id int,
	@acc_id int

DECLARE @rec_id int


SELECT @did = DEPO_ID, @op_type = OP_TYPE, @docs_rec_id = DOC_REC_ID 
FROM dbo.DEPO_OPS
WHERE OP_ID = @oid

UPDATE dbo.DEPO_OPS 
SET COMMIT_STATE = 0, COMMITER_OWNER = NULL, DOC_REC_ID = NULL
WHERE OP_ID = @oid
IF @@ERROR<>0 RETURN (1)

DECLARE @start_dt smalldatetime
DECLARE @end_date smalldatetime

SELECT @st = REC_STATE 
FROM dbo.DEPO_DATA
WHERE OP_ID = dbo.depo_get_last_prev_op_id (@did)

UPDATE dbo.DEPO_DATA
SET REC_STATE = @st
WHERE OP_ID = @oid

SELECT @acc_id = ACC_ID, @start_dt = START_DATE
FROM dbo.DEPOS
WHERE DEPO_ID = @did


IF @op_type = 20 -- ÀÍÀÁÀÒÉÓ ÀØÔÉÅÉÆÀÝÉÀ
BEGIN
	DELETE FROM dbo.ACCOUNTS_CRED_PERC WHERE ACC_ID = @acc_id
	IF @@ERROR<>0 BEGIN RAISERROR('ÛÄÝÃÏÌÀ ÀÍÀÁÀÒÉÓ ÀÍÂÀÒÉÛÆÄ ÃÀÒÉÝáÅÉÓ ÓØÄÌÉÓ ÂÀÖØÌÄÁÉÓÀÓ!', 16, 1) RETURN (21) END
END
ELSE
IF @op_type = 30 -- ÀÍÀÁÀÒÉÓ ÐÒÏËÏÍÂÀÝÉÀ
BEGIN
	SELECT @end_date = END_DATE
	FROM dbo.DEPO_DATA
	WHERE OP_ID = dbo.depo_get_prev_op_id (@did, @oid)     

	UPDATE dbo.ACCOUNTS_CRED_PERC
	SET END_DATE = @end_date, FORMULA = dbo.depo_get_formula(dbo.depo_get_prev_op_id(@did, @oid)) 
	FROM dbo.ACCOUNTS_CRED_PERC A 
	WHERE A.ACC_ID = @acc_id

	IF @@ERROR<>0 OR @@ROWCOUNT=0 BEGIN RAISERROR('ÛÄÝÃÏÌÀ ÀÍÀÁÀÒÉÓ ÀÍÂÀÒÉÛÆÄ ÃÀÒÉÝáÅÉÓ ÓØÄÌÉÓ ÀÙÃÂÄÍÉÓÀÓ!', 16, 1) RETURN (31) END
END
ELSE
IF @op_type = 40 -- ÀÍÀÁÀÒÉÓ ÓÀÐÒÏÝÄÍÔÏ ÂÀÍÀÊÅÄÈÉÓ ÝÅËÉËÄÁÀ
BEGIN
	UPDATE dbo.ACCOUNTS_CRED_PERC
	SET FORMULA = dbo.depo_get_formula(dbo.depo_get_prev_op_id(@did, @oid)) 
	FROM dbo.ACCOUNTS_CRED_PERC A 
	WHERE A.ACC_ID = @acc_id

	IF @@ERROR<>0 OR @@ROWCOUNT=0 BEGIN RAISERROR('ÛÄÝÃÏÌÀ ÀÍÀÁÀÒÉÓ ÀÍÂÀÒÉÛÆÄ ÃÀÒÉÝáÅÉÓ ÓØÄÌÉÓ ÀÙÃÂÄÍÉÓÀÓ!', 16, 1) RETURN (41) END
	
	INSERT INTO dbo.ACC_CHANGES (ACC_ID,[USER_ID],DESCRIP)
	VALUES (@acc_id,@user_id,'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : PERIOD (ÀÍÀÁÒÉÓ ÐÒÏËÏÍÂÀÝÉÀ)')
	IF @@ERROR<>0 RETURN(220)
	
	SET @rec_id = SCOPE_IDENTITY()
	
	INSERT INTO dbo.ACCOUNTS_ARC
	SELECT @rec_id, *
	FROM dbo.ACCOUNTS
	WHERE ACC_ID = @acc_id
    IF @@ERROR<>0 RETURN(220)

	UPDATE dbo.ACCOUNTS
	SET PERIOD = @end_date
	WHERE ACC_ID = @acc_id
	IF @@ERROR<>0 RETURN(220)
END
/*
ELSE
IF @op_type = 50 -- ÀÍÀÁÀÒÉÓ ÒÄÓÔÒÖØÔÖÒÉÆÀÝÉÀ
BEGIN
DELETE dbo.ACCOUNTS_CRED_PERC WHERE ACC_ID = @acc_id
IF @@ERROR<>0 BEGIN
  RAISERROR('ÛÄÝÃÏÌÀ ÀÍÀÁÀÒÉÓ ÀÍÂÀÒÉÛÆÄ ÃÀÒÉÝáÅÉÓ ÓØÄÌÉÓ ÀÙÃÂÄÍÉÓÀÓ!', 16, 1)
  RETURN (51)
END

INSERT INTO dbo.ACCOUNTS_CRED_PERC
 (ACC_ID, START_DATE, END_DATE, MOVE_COUNT, MOVE_COUNT_TYPE, CALC_TYPE, FORMULA, CLIENT_ACCOUNT, PERC_CLIENT_ACCOUNT, 
  PERC_BANK_ACCOUNT, PERC_BANK_ACCOUNT_OLD, DAYS_IN_YEAR, ALREADY_CALCED_AMOUNT, PERC_FLAGS, ALREADY_PAYED_AMOUNT, PERC_TYPE, TAX_RATE)
SELECT
  @account, @iso, @start_dt, END_DATE, MOVE_COUNT, MOVE_COUNT_TYPE, CALC_TYPE, FORMULA, CLIENT_ACCOUNT, PERC_CLIENT_ACCOUNT, 
  PERC_BANK_ACCOUNT, Null, DAYS_IN_YEAR, ALREADY_CALCED_AMOUNT, PERC_FLAGS, ALREADY_PAYED_AMOUNT, PERC_TYPE, TAX_RATE
FROM
  dbo.DX_DEPOSIT_DATA
WHERE OID=dbo.depo_get_prev_op_id(@did, @oid) 

IF @@ERROR<>0 OR @@ROWCOUNT=0 BEGIN RAISERROR('ÛÄÝÃÏÌÀ ÀÍÀÁÀÒÉÓ ÀÍÂÀÒÉÛÆÄ ÃÀÒÉÝáÅÉÓ ÓØÄÌÉÓ ÀÙÃÂÄÍÉÓÀÓ!', 16, 1) RETURN (51) END END
*/
ELSE
IF @op_type = 220 -- ÀÍÀÁÀÒÉÓ ÃÀáÖÒÅÀ
BEGIN
	SELECT @end_date = END_DATE  
	FROM dbo.DEPO_DATA (NOLOCK)
	WHERE OP_ID = dbo.depo_get_prev_op_id (@did, @oid) 

	UPDATE dbo.ACCOUNTS_CRED_PERC
	SET END_DATE = @end_date
	WHERE ACC_ID = @acc_id

	IF @@ERROR<>0 OR @@ROWCOUNT=0 BEGIN RAISERROR('ÛÄÝÃÏÌÀ ÀÍÀÁÀÒÉÓ ÀÍÂÀÒÉÛÆÄ ÃÀÒÉÝáÅÉÓ ÓØÄÌÉÓ ÀÙÃÂÄÍÉÓÀÓ!', 16, 1) RETURN (221) END
END

DECLARE @r int

EXEC @r = dbo.DX_SPX_DELETE_EXEC_OPS_ACCOUNTING @docs_rec_id=@docs_rec_id, @oid=@oid, @user_id=@user_id
IF @@ERROR<>0 OR @r <> 0 RETURN(11)


RETURN (0)
GO
