SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_exec_op]
  @doc_rec_id int OUTPUT,
  @oid int,
  @user_id int
AS

SET NOCOUNT ON

DECLARE 
	@e int, 
	@r int

DECLARE	@rec_id int

DECLARE -- ÏÐÄÒÀÝÉÉÓ ÌÏÍÀÝÄÌÄÁÉ
	@did int,
	@dt smalldatetime,
	@op_type int,
	@own_data bit,
	@op_amount money    

SELECT @did = DEPO_ID, @dt = DT, @op_type = OP_TYPE, @own_data = OWN_DATA, @op_amount = AMOUNT
FROM dbo.DEPO_OPS 
WHERE OP_ID = @oid

DECLARE -- ÀÍÀÁÒÉÓ ÌÏÍÀÝÄÌÄÁÉ
	@start_dt smalldatetime,
	@deposit_type int,
	@iso TISO,
	@acc_id int

SELECT @acc_id = ACC_ID, @start_dt = START_DATE, @deposit_type = DEPO_TYPE_ID, @iso = ISO
FROM dbo.DEPOS
WHERE DEPO_ID = @did
  
DECLARE -- ÀÍÀÁÀÒÉÓ ÝÅËÀÃÉ ÌÏÍÀÝÄÌÄÁÉ
	@st int,
	@end_dt smalldatetime

SELECT @st = REC_STATE, @end_dt = END_DATE
FROM dbo.DEPO_DATA 
WHERE OP_ID = @oid

DECLARE	@commited_oid int

SELECT @commited_oid = MAX(OP_ID)
FROM dbo.DEPO_OPS 
WHERE DEPO_ID = @did AND OP_ID < @oid AND COMMIT_STATE = 0xFF

IF @op_type IN (30, 40, 50) -- (ÀÍÀÁÒÉÓ ÐÒÏËÏÍÂÀÝÉÀ, ÀÍÀÁÀÒÉÓ ÓÀÐÒÏÝÄÍÔÏ ÂÀÍÀÊÅÄÈÉÓ ÝÅËÉËÄÁÀ, ÀÍÀÁÀÒÉÓ ÒÄÓÔÒÖØÔÖÒÉÆÀÝÉÀ)
BEGIN
	EXEC @r = dbo.PROCESS_ACCRUAL
		@perc_type = 0,
		@acc_id = @acc_id,
		@user_id = @user_id,
		@dept_no = NULL, -- ÀÉÙÏÓ ÂÀÍÚÏ×ÉËÄÁÀ ÌÏÌáÌÀÒÄÁËÉÃÀÍ
		@doc_date = @dt,
		@calc_date = @dt,
		@force_calc = 1,
		@force_realization = 0,
		@simulate = 0,
		@recalc_option = 0
	IF @@ERROR<>0 OR @r<>0 RETURN(30)
END

IF @op_type = 20 -- ÀÍÀÁÀÒÉÓ ÀØÔÉÅÉÆÀÝÉÀ
BEGIN
	IF EXISTS(SELECT * FROM dbo.ACCOUNTS_CRED_PERC WHERE ACC_ID = @acc_id) 
	BEGIN
		RAISERROR ('ÀÍÀÁÒÉÓ ÀÍÂÀÒÉÛÆÄ ÃÀÊÀÅÛÉÒÄÁÖËÉÀ ÊÒÄÃÉÔÖË ÍÀÛÈÆÄ ÃÀÒÉÝáÅÉÓ ÓØÄÌÀ!',16,1) 
		RETURN (21)
	END
	
	INSERT INTO dbo.ACCOUNTS_CRED_PERC
		(ACC_ID, START_DATE, END_DATE, MOVE_COUNT, MOVE_COUNT_TYPE, CALC_TYPE, FORMULA, CLIENT_ACCOUNT, PERC_CLIENT_ACCOUNT, 
		PERC_BANK_ACCOUNT, DAYS_IN_YEAR, CALC_AMOUNT, PERC_FLAGS, PERC_TYPE, TAX_RATE, START_DATE_TYPE, START_DATE_DAYS, DATE_TYPE)
	SELECT
		@acc_id, @start_dt, END_DATE, MOVE_COUNT, MOVE_COUNT_TYPE, CALC_TYPE, FORMULA, CLIENT_ACCOUNT, PERC_CLIENT_ACCOUNT, 
		PERC_BANK_ACCOUNT, DAYS_IN_YEAR, CALC_AMOUNT, PERC_FLAGS, PERC_TYPE, TAX_RATE, START_DATE_TYPE, START_DATE_DAYS, 
		ISNULL(DATE_TYPE, 1) AS DATE_TYPE -- ÉÌÀÈÈÅÉÓ ÅÉÓÈÅÉÓÀÝ ÃÀÒÙÅÄÅÉÓ ÌÄÈÏÃÉ ÀÒ ÀÒÉÓ!
	FROM dbo.DEPO_DATA
	WHERE OP_ID = @oid  
	IF @@ERROR<>0 RETURN(22)

    INSERT INTO dbo.ACCOUNTS_CRED_PERC_DETAILS(ACC_ID, DAYS, PERC)
	SELECT @acc_id, DAYS, PERC 
	FROM dbo.DEPO_DATA_ANNULMENT_DETAILS 
	WHERE OP_ID = @oid


	DECLARE
		@prev_period smalldatetime,
		@next_period smalldatetime

	SELECT @prev_period = PERIOD
	FROM dbo.ACCOUNTS (NOLOCK)
	WHERE ACC_ID = @acc_id	

	SELECT @next_period = END_DATE
	FROM dbo.DEPO_DATA
	WHERE OP_ID = @oid  

	IF @prev_period IS NULL OR (@prev_period <> @next_period)
	BEGIN
		INSERT INTO dbo.ACC_CHANGES (ACC_ID,[USER_ID],DESCRIP)
		VALUES (@acc_id,@user_id,'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : PERIOD (ÀÍÀÁÒÉÓ ÒÄÃÀØÔÉÒÄÁÀ)')
		IF @@ERROR<>0 RETURN(220)
		
		SET @rec_id = SCOPE_IDENTITY()
		
		INSERT INTO dbo.ACCOUNTS_ARC
		SELECT @rec_id, *
		FROM dbo.ACCOUNTS
		WHERE ACC_ID = @acc_id
		IF @@ERROR<>0 RETURN(30)

		UPDATE dbo.ACCOUNTS
		SET PERIOD = @next_period
		WHERE ACC_ID = @acc_id
		IF @@ERROR<>0 OR @r<>0 RETURN(30)
	END
END
ELSE
IF @op_type = 30 -- ÀÍÀÁÀÒÉÓ ÐÒÏËÏÍÂÀÝÉÀ
BEGIN
	DECLARE
		@new_end_date smalldatetime,
		@formula_prolong varchar(255)

	SET @formula_prolong = dbo.depo_get_formula (@oid) 

	SELECT @new_end_date = EXT_DATE
	FROM dbo.DEPO_OPS
	WHERE OP_ID = @oid 

	UPDATE dbo.ACCOUNTS_CRED_PERC
	SET END_DATE = @new_end_date, FORMULA = @formula_prolong 
	WHERE ACC_ID = @acc_id
	IF @@ERROR<>0 OR @r<>0 RETURN(30)

	INSERT INTO dbo.ACC_CHANGES (ACC_ID,[USER_ID],DESCRIP)
	VALUES (@acc_id,@user_id,'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : PERIOD (ÀÍÀÁÒÉÓ ÐÒÏËÏÍÂÀÝÉÀ)')
	IF @@ERROR<>0 RETURN(220)
	
	SET @rec_id = SCOPE_IDENTITY()
	
	INSERT INTO dbo.ACCOUNTS_ARC
	SELECT @rec_id, *
	FROM dbo.ACCOUNTS
	WHERE ACC_ID = @acc_id
    IF @@ERROR<>0 RETURN(30)

	UPDATE dbo.ACCOUNTS
	SET PERIOD = @new_end_date
	WHERE ACC_ID = @acc_id
	IF @@ERROR<>0 OR @r<>0 RETURN(30)
END
ELSE
IF @op_type = 40 -- ÀÍÀÁÀÒÉÓ ÓÀÐÒÏÝÄÍÔÏ ÂÀÍÀÊÅÄÈÉÓ ÝÅËÉËÄÁÀ
BEGIN
	DECLARE	@formula varchar(255)
	SET @formula = dbo.depo_get_formula(@oid) 

	UPDATE dbo.ACCOUNTS_CRED_PERC
	SET FORMULA = @formula
	WHERE ACC_ID = @acc_id
	IF @@ERROR<>0 OR @r<>0 RETURN(40)
END
ELSE
IF @op_type = 50 -- ÀÍÀÁÀÒÉÓ ÒÄÓÔÒÖØÔÖÒÉÆÀÝÉÀ
BEGIN
	UPDATE P
	SET P.MOVE_COUNT = D.MOVE_COUNT,
		P.MOVE_COUNT_TYPE = D.MOVE_COUNT_TYPE,
		P.CALC_TYPE = D.CALC_TYPE,
		P.FORMULA = D.FORMULA, 
		P.CLIENT_ACCOUNT = D.CLIENT_ACCOUNT, 
		P.PERC_CLIENT_ACCOUNT = D.PERC_CLIENT_ACCOUNT, 
		P.PERC_BANK_ACCOUNT = D.PERC_BANK_ACCOUNT, 
		P.DAYS_IN_YEAR = D.DAYS_IN_YEAR, 
		P.CALC_AMOUNT = D.CALC_AMOUNT, 
		P.PERC_FLAGS = D.PERC_FLAGS, 
		P.PERC_TYPE = D.PERC_TYPE, 
		P.TAX_RATE = D.TAX_RATE, 
		P.START_DATE_TYPE = D.START_DATE_TYPE, 
		P.START_DATE_DAYS = D.START_DATE_DAYS, 
		P.DATE_TYPE = D.DATE_TYPE
	FROM dbo.ACCOUNTS_CRED_PERC P
		INNER JOIN dbo.DEPO_DATA D ON D.OP_ID = @oid
	WHERE P.ACC_ID = @acc_id

	IF @@ERROR <> 0
	BEGIN
		RAISERROR('ÛÄÝÃÏÌÀ ÀÍÀÁÀÒÉÓ ÀÍÂÀÒÉÛÆÄ ÃÀÒÉÝáÅÉÓ ÓØÄÌÉÓ ÀÙÃÂÄÍÉÓÀÓ!', 16, 1)
		RETURN (51)
	END
END
ELSE
IF @op_type = 210 -- ÀÍÀÁÀÒÉÓ ÃÀÒÙÅÄÅÉÈ ÃÀáÖÒÅÀ
BEGIN
	EXEC @r = dbo.PROCESS_CRED_ANNUL
		@acc_id = @acc_id,
		@annul_date = @dt,
		@user_id = @user_id,
		@doc_rec_id = @doc_rec_id OUTPUT

	IF @r <> 0 OR @@ERROR <> 0
	BEGIN
		RAISERROR('ÛÄÝÃÏÌÀ ÀÍÀÁÀÒÉÓ ÃÀÒÙÅÄÅÉÓÀÓ!', 16, 1)
		RETURN (51)
	END
END
/*ELSE
IF @op_type = 220 -- ÀÍÀÁÀÒÉÓ ÃÀáÖÒÅÀ
BEGIN
	DECLARE	@rec_id int

	UPDATE dbo.ACCOUNTS_CRED_PERC
	SET END_DATE = @dt
	WHERE ACC_ID = @acc_id
	IF @@ERROR<>0 OR @r<>0 RETURN(220)

	INSERT INTO dbo.ACC_CHANGES (ACC_ID,[USER_ID],DESCRIP)
	VALUES (@acc_id,@user_id,'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : REC_STATE DATE_CLOSE (ÀÍÀÁÒÉÓ ÃÀáÖÒÅÀ)')
	IF @@ERROR<>0 RETURN(220)
	
	SET @rec_id = SCOPE_IDENTITY()
	
	INSERT INTO dbo.ACCOUNTS_ARC
	SELECT @rec_id, *
	FROM dbo.ACCOUNTS
	WHERE ACC_ID = @acc_id
    IF @@ERROR<>0 RETURN(220)

	UPDATE dbo.ACCOUNTS
	SET REC_STATE = 2, DATE_CLOSE = @dt
	WHERE ACC_ID = @acc_id
    IF @@ERROR<>0 RETURN(220)
END
*/  

DECLARE
    @st_set int,
    @st_clear int
SET @st_set = 0
SET @st_clear =0xFFFF
  

SET @st_set =
    CASE @op_type 
      WHEN 20  THEN 0x0001     -- ÀÍÀÁÀÒÉÓ ÀØÔÉÅÉÆÀÝÉÀ
      WHEN 30  THEN 0x0006     -- ÀÍÀÁÀÒÉÓ ÐÒÏËÏÍÂÀÝÉÀ
      WHEN 40  THEN 0x0004     -- ÀÍÀÁÀÒÉÓ ÓÀÐÒÏÝÄÍÔÏ ÂÀÍÀÊÅÄÈÉÓ ÝÅËÉËÄÁÀ
      WHEN 50  THEN 0x0008     -- ÀÍÀÁÀÒÉÓ ÒÄÓÔÒÖØÔÖÒÉÆÀÝÉÀ       
      WHEN 60  THEN 0x0010     -- ÀÍÀÁÀÒÉÓ ÛÄÅÓÄÁÀ
      WHEN 70  THEN 0x0020     -- ÐÀÓÖáÉÓÌÂÄÁÄËÉ Ï×ÉÝÒÉÓ ÃÀÍÉÛÅÍÀ ÀÍÀÁÀÒÆÄ
	  WHEN 210 THEN 0xF000     -- ÀÍÀÁÀÒÉÓ ÃÀÒÙÅÄÅÉÈ ÃÀáÖÒÅÀ
      WHEN 220 THEN 0xF000     -- ÀÍÀÁÀÒÉÓ ÃÀáÖÒÅÀ
      ELSE 0
    END   

UPDATE dbo.DEPO_DATA
SET REC_STATE = (REC_STATE | @st_set) & @st_clear
WHERE OP_ID = @oid

UPDATE dbo.DEPO_OPS 
SET COMMIT_STATE = 0xFF, COMMITER_OWNER = @user_id 
WHERE OP_ID = @oid
IF @@ERROR <> 0 RETURN(1)

EXEC @r = dbo.depo_exec_op_accounting @doc_rec_id OUTPUT, @user_id=@user_id, @oid=@oid
IF @@ERROR<>0 OR @r<>0 BEGIN SET @doc_rec_id = 0 RETURN(1) END

IF ISNULL(@doc_rec_id, -1) <> 0
BEGIN
	UPDATE dbo.DEPO_OPS 
	SET DOC_REC_ID = @doc_rec_id 
	WHERE OP_ID = @oid
END

-- >>> added by PCBG 20060721
--EXEC dbo.PCB_DX_DEPOSIT_OPS @op_type = 20, @action = 1, @acc_id = @acc_id
-- <<< added by PCBG

RETURN (0)
GO
