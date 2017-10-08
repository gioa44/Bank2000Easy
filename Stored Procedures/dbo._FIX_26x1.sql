SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[_FIX_26x1]
	@dt smalldatetime,
	@start_of_day bit
AS

SET NOCOUNT ON

DECLARE
	@head_branch_id int,

	@account_2601 TACCOUNT,
	@account_86 TACCOUNT,
	@account_66 TACCOUNT,
	
	@acc_id_2601 int,
	@acc_id_86 int,
	@acc_id_66 int,

	@delta money,
	@descrip varchar(100)

SET @head_branch_id = dbo.bank_head_branch_id()
 
EXEC dbo.GET_SETTING_ACC 'CONV_ACC_2601', @account_2601 OUTPUT

IF @start_of_day = 0 -- End of day
BEGIN
	EXEC dbo.GET_DEPT_ACC @head_branch_id, 'CONV_ACC_19_1A', @account_86 OUTPUT
	EXEC dbo.GET_DEPT_ACC @head_branch_id, 'CONV_ACC_19_1P', @account_66 OUTPUT
	SET @descrip = 'ÃÙÉÓ ÓÀÄÒÈÏ ÓÀÊÖÒÓÏ ÓáÅÀÏÁÀ'
END
ELSE	 -- start of day, revaluation
BEGIN
	EXEC dbo.GET_SETTING_ACC 'CONV_ACC_8621', @account_86 OUTPUT
	EXEC dbo.GET_SETTING_ACC 'CONV_ACC_6621', @account_66 OUTPUT
	SET @descrip = 'ÂÀÃÀ×ÀÓÄÁÉÈ ÌÉÙÄÁÖËÉ ÓÀÊÖÒÓÏ ÓáÅÀÏÁÀ'
END

DECLARE @shadow_level smallint
SET @shadow_level = CASE WHEN @start_of_day = 1 THEN -1 ELSE 0 END

SET @acc_id_2601 = dbo.acc_get_acc_id(@head_branch_id, @account_2601, 'GEL')
SET @acc_id_86 = dbo.acc_get_acc_id(@head_branch_id, @account_86, 'GEL')
SET @acc_id_66 = dbo.acc_get_acc_id(@head_branch_id, @account_66, 'GEL')

SELECT @delta = SUM( dbo.acc_get_balance ( A.ACC_ID, @dt, 0, 1, @shadow_level) )
FROM dbo.ACCOUNTS A
WHERE ((A.BAL_ACC_ALT >= 2611 AND A.BAL_ACC_ALT < 2612 AND A.ISO <> 'GEL') OR 
	(A.BAL_ACC_ALT >= 2601 AND A.BAL_ACC_ALT < 2602 AND A.ISO = 'GEL'))
 
DECLARE 
	@r int,
	@rec_id int,
	@debit_id int,
	@credit_id int
 
SET @delta = - ROUND(@delta, 2)
 
IF @delta < $0.0000
BEGIN
	SET @debit_id = @acc_id_86
	SET @credit_id = @acc_id_2601
	SET @delta = -@delta
END
ELSE
IF @delta > $0.0000
BEGIN
	SET @debit_id = @acc_id_2601
	SET @credit_id = @acc_id_66
END
 
IF @delta <> $0.0000
BEGIN
	DECLARE @doc_num int
	SET @doc_num = CASE WHEN @start_of_day = 1 THEN 1 ELSE 2 END

	EXEC @r = dbo._INTERNAL_ADD_DOC
		@rec_id = @rec_id OUTPUT,   
		@owner = 3, -- Close day
		@doc_type = 97,
		@doc_date = @dt,
		@debit_id = @debit_id,
		@credit_id = @credit_id,
		@iso = 'GEL',
		@amount = @delta,
		@rec_state = 20,
		@descrip = @descrip,
		@op_code = '*CVR*',
		@parent_rec_id = 0,
		@doc_num = @doc_num,
		@dept_no = @head_branch_id,
		@channel_id=0,
		@prod_id = 0,
		@flags = 1
	IF @@ERROR<>0 OR @r<>0 RETURN 1
END
 
RETURN (0)
GO
