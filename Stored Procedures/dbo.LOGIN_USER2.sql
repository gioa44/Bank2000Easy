SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[LOGIN_USER2]
	@loginame varchar(128),
	@dept_id int OUTPUT,	-- INPUT & OUTPUT
	@password varchar(32),
	@user_id int OUTPUT,
	@user_full_name varchar(50) OUTPUT,	@group_id int OUTPUT,
	@info varchar(255)  OUTPUT,
	@user_psw_change bit OUTPUT,
	@user_psw_cant_change bit OUTPUT,
	@user_psw_exp_date smalldatetime OUTPUT,
	@is_client_manager bit OUTPUT,
	@is_cashier bit = null OUTPUT,
	@is_operator_cashier bit OUTPUT,
	@is_acc_manager bit OUTPUT,
	@is_callcenter_operator bit OUTPUT
AS

SET NOCOUNT ON

SET  @info = ''
SET  @group_id = 0

SELECT @is_client_manager = 0, @is_operator_cashier = 0, @is_acc_manager = 0, @is_callcenter_operator = 0

DECLARE @srv_state int

SELECT @srv_state = VALS
FROM dbo.INI_INT (NOLOCK)
WHERE IDS = 'SERVER_STATE'

IF @srv_state = 1 
BEGIN
  SELECT @info = 'ÓÄÒÅÄÒÉ ÃÀÊÀÅÄÁÖËÉÀ, ÌÉÌÃÉÍÀÒÄÏÁÓ ÃÙÉÓ ÃÀáÖÒÅÀ. ÛÄÄÝÀÃÄÈ ÌÉÄÒÈÄÁÀ ÒÀÌÏÃÄÍÉÌÄ ßÖÈÛÉ.'
  RETURN (21)
END

IF @srv_state = 2
BEGIN
  SELECT @info = 'ÓÄÒÅÄÒÉ ÃÀÊÀÅÄÁÖËÉÀ, ÌÉÌÃÉÍÀÒÄÏÁÓ ÃÙÉÓ ÖÊÀÍ ÃÀÁÒÖÍÄÁÀ. ÛÄÄÝÀÃÄÈ ÌÉÄÒÈÄÁÀ ÒÀÌÏÃÄÍÉÌÄ ßÖÈÛÉ.'
  RETURN (22)
END
  
DECLARE @lock_flag bit, @del_flag bit

EXEC dbo.ON_USER_LOGIN_USER @loginame=@loginame, @password=@password, @user_id=@user_id OUTPUT

IF @user_id IS NULL

	SELECT  
		@user_id = [USER_ID],
		@user_full_name  = USER_FULL_NAME,
		@group_id	 = GROUP_ID,
		@lock_flag	 = LOCK_FLAG,
		@del_flag  = USER_DEL_FLAG,
		@dept_id	 = DEPT_NO,
		@user_psw_change = USER_PSW_CHANGE,
		@user_psw_cant_change = USER_PSW_CANT_CHANGE,
		@user_psw_exp_date = USER_PSW_EXP_DATE,
		@is_client_manager = ISNULL(IS_CLIENT_MANAGER, 0),
		@is_cashier = ISNULL(IS_CASHIER, 0),
		@is_operator_cashier = ISNULL(IS_OPERATOR_CASHIER, 0),
		@is_acc_manager = ISNULL(IS_ACC_MANAGER, 0),
		@is_callcenter_operator = ISNULL(IS_CALL_CENTER_OPERATOR, 0)
	FROM  dbo.USERS (NOLOCK)
	WHERE  [USER_NAME] = @loginame and PSWHASH = @password AND (@dept_id IS NULL OR dbo.dept_branch_id(DEPT_NO) = @dept_id)
ELSE
	SELECT  
		@user_full_name  = USER_FULL_NAME,
		@group_id	 = GROUP_ID,
		@lock_flag	 = LOCK_FLAG,
		@del_flag  = USER_DEL_FLAG,
		@dept_id	 = DEPT_NO,
		@user_psw_change = USER_PSW_CHANGE,
		@user_psw_cant_change = USER_PSW_CANT_CHANGE,
		@user_psw_exp_date = USER_PSW_EXP_DATE,
		@is_client_manager = ISNULL(IS_CLIENT_MANAGER, 0),
		@is_cashier = ISNULL(IS_CASHIER, 0),
		@is_operator_cashier = ISNULL(IS_OPERATOR_CASHIER, 0),
		@is_acc_manager = ISNULL(IS_ACC_MANAGER, 0),
		@is_callcenter_operator = ISNULL(IS_CALL_CENTER_OPERATOR, 0)
	FROM  dbo.USERS (NOLOCK)
	WHERE  [USER_ID] = @user_id

IF @user_id IS NULL
BEGIN
	SELECT @info = 'ÌÏÌáÌÀÒÄÁËÉÓ ÓÀáÄËÉ ÀÍ ÐÀÒÏËÉ ÀÒ ÀÒÉÓ ÓßÏÒÉ.'
	RETURN (1)
END

IF @group_id < 0
BEGIN 
	EXEC dbo.user_smart_card_unregister @user_id, @saved_group_id = @group_id OUTPUT
END

IF @del_flag = 1
BEGIN
	SELECT @info = 'ÌÏÌáÌÀÒÄÁÄËÉ ÂÀÖØÌÄÁÖËÉÀ'
	RETURN (2)
END

IF @lock_flag = 1
BEGIN
	SELECT @info = 'ÌÏÌáÌÀÒÄÁÄËÉ ÁËÏÊÉÒÄÁÖËÉÀ'
	RETURN (2)
END

IF (NOT @user_psw_exp_date IS NULL) AND (GETDATE() > @user_psw_exp_date+1)
	SET @user_psw_change = 1

IF (SELECT DATABASEPROPERTYEX (DB_NAME(), 'Updateability')) <> 'READ_ONLY'
	UPDATE dbo.USERS
	SET USER_LAST_LOGIN = GETDATE()
	WHERE [USER_ID] = @user_id

/* We just check the existance, the value will be obtained by appSrv */

IF NOT EXISTS (SELECT GROUP_ID FROM dbo.GROUPS WHERE GROUP_ID = @group_id)BEGIN
	SELECT @info = 'Invalid Access Right'
	RETURN (4)
END

RETURN (0)
GO
