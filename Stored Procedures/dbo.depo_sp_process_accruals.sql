SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[depo_sp_process_accruals]
	@user_id int,
	@dept_no int,
	@doc_date smalldatetime,
	@calc_date smalldatetime,
	@date_type tinyint, -- 0-> ÖÍÃÀ ÂÀÃÌÏÄÝÄÓ ÐÒÏÃÖØÔÄÁÉÓ ËÉÓÔÉ, 1 -> ÃÙÉÓ ÃÀÓÀßÚÉÓÛÉ ÃÀÓÀÒÉÝáÉ ÐÒÏÃÖØÔÄÁÉ, 2 -> ÃÙÉÓ ÁÏËÏÓ ÃÀÓÀÒÉÝáÉ ÐÒÏÃÖØÔÄÁÉ
	@products varchar(255) = NULL
AS

DECLARE
	@r int

DECLARE
	@date smalldatetime

SET @date = CASE WHEN @calc_date > @doc_date THEN @calc_date ELSE @doc_date END

EXEC @r = dbo.depo_sp_sync_depo_b2000
	@depo_id = NULL,
	@user_id = @user_id,
	@date = @date

IF @@ERROR <> 0 OR @r <> 0 RETURN 1;

IF @date_type = 1
	EXEC dbo.GET_SETTING_STR 'DEPO_DAY_START_PRODS', @products OUTPUT
IF @date_type = 2
	EXEC dbo.GET_SETTING_STR 'DEPO_DAY_END_PRODS', @products OUTPUT

DECLARE
	@depo_id int,
	@acc_id int

DECLARE cc CURSOR FAST_FORWARD READ_ONLY LOCAL
FOR 
SELECT D.DEPO_ID, P.ACC_ID
FROM dbo.ACCOUNTS_CRED_PERC (NOLOCK) P 
	INNER JOIN dbo.ACCOUNTS (NOLOCK) A ON A.ACC_ID = P.ACC_ID
	INNER JOIN dbo.DEPO_DEPOSITS (NOLOCK) D ON A.ACC_ID = D.DEPO_ACC_ID
	INNER JOIN dbo.fn_split_list_int(@products, ';') PR ON D.PROD_ID = PR.[ID]
WHERE A.REC_STATE NOT IN (2, 64, 128) AND (D.STATE >= 50 AND D.STATE < 240) AND
	(P.START_DATE <= @calc_date) AND ((P.END_DATE IS NULL OR P.END_DATE >= @calc_date) OR 
	(P.END_DATE < @calc_date AND DAY(@calc_date + 1) = 1 AND MONTH(P.END_DATE) = MONTH(@calc_date) AND YEAR(P.END_DATE) = YEAR(@calc_date)))

OPEN cc
FETCH NEXT FROM cc INTO @depo_id, @acc_id
WHILE @@FETCH_STATUS = 0
BEGIN

	IF EXISTS(SELECT * FROM dbo.DEPO_OP (NOLOCK) WHERE DEPO_ID = @depo_id AND OP_STATE = 0)
		GOTO _NEXT

	EXEC @r = dbo.depo_sp_process_deposits_before_accrual
		@user_id = @user_id,
		@dept_no = @dept_no,
		@doc_date = @doc_date,
		@calc_date = @calc_date,
		@acc_id = @acc_id,
		@depo_id = @depo_id
	
	IF @@ERROR <> 0 OR @r <> 0
	BEGIN
		CLOSE cc
		DEALLOCATE cc
		RETURN 102
	END 	

	EXEC dbo.PROCESS_ACCRUAL
		@perc_type = 0, 
		@acc_id = @acc_id,
		@user_id = @user_id,
		@dept_no = @dept_no,
		@doc_date = @doc_date,
		@calc_date = @calc_date,
		@force_calc = 0,
		@force_realization = 0,
		@simulate = 0,
		@depo_depo_id = @depo_id
		
	IF @@ERROR <> 0
	BEGIN
		CLOSE cc
		DEALLOCATE cc
		RETURN 100
	END

	EXEC @r = dbo.depo_sp_sync_depo_b2000
		@depo_id = @depo_id,
		@user_id = @user_id,
		@date = @date
	 	
	IF @@ERROR <> 0 OR @r <> 0
	BEGIN
		CLOSE cc
		DEALLOCATE cc
		RETURN 100
	END
	
	EXEC @r = dbo.depo_sp_process_deposits
		@user_id = @user_id,
		@dept_no = @dept_no,
		@doc_date = @doc_date,
		@calc_date = @calc_date,
		@acc_id = @acc_id,
		@depo_id = @depo_id
	
	IF @@ERROR <> 0 OR @r <> 0
	BEGIN
		CLOSE cc
		DEALLOCATE cc
		RETURN 103
	END 	

	EXEC @r = dbo.depo_sp_sync_depo_b2000
		@depo_id = @depo_id,
		@user_id = @user_id,
		@date = @date
	 	
	IF @@ERROR <> 0 OR @r <> 0
	BEGIN
		CLOSE cc
		DEALLOCATE cc
		RETURN 100
	END

_NEXT:
	FETCH NEXT FROM cc INTO @depo_id, @acc_id
END

CLOSE cc
DEALLOCATE cc

EXEC @r = dbo.depo_sp_sync_depo_b2000
	@depo_id = NULL,
	@user_id = @user_id,
	@date = @date

IF @@ERROR <> 0 OR @r <> 0 RETURN 1;

RETURN 0;
GO
