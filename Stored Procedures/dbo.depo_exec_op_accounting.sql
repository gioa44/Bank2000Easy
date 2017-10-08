SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_exec_op_accounting]
  @doc_rec_id int OUTPUT,
  @user_id int,
  @oid int
AS

SET NOCOUNT ON

DECLARE @r int

DECLARE
	@acc_id int,
	@did int,
	@dt smalldatetime,
	@op_type int,
	@amount money,
	@dept_no int,
	@client_no int

SELECT @did = DEPO_ID, @dt = DT, @op_type = OP_TYPE, @amount = AMOUNT 
FROM dbo.DEPO_OPS 
WHERE OP_ID = @oid

IF @op_type = 70 -- ÐÀÓÖáÉÓÌÂÄÁÄËÉ Ï×ÉÝÒÉÓ ÃÀÍÉÛÅÍÀ ÀÍÀÁÀÒÆÄ
	RETURN(0)

DECLARE
	@iso TISO,
	@dno varchar(50)

SELECT @acc_id = ACC_ID, @client_no = CLIENT_NO, @dept_no = DEPT_NO, @iso = ISO, @dno=DEPO_NO
FROM dbo.DEPOS
WHERE DEPO_ID = @did

IF @op_type = 20 -- ÀÍÀÁÒÉÓ ÀØÔÉÅÉÆÀÝÉÀ
BEGIN
	EXEC @r = dbo.depo_exec_op_accounting_active
		@doc_rec_id OUTPUT, 
		@user_id = @user_id, 
		@did = @did, 
		@oid = @oid, 
		@acc_id = @acc_id,
		@dno = @dno, 
		@dt = @dt, 
		@op_type = @op_type, 
		@amount = @amount, 
		@iso = @iso,
		@client_no = @client_no, 
		@dept_no = @dept_no
    IF @@ERROR<>0 OR @r<>0 BEGIN SET @doc_rec_id = 0 RETURN @r END
END
ELSE
IF @op_type = 220 -- ÀÍÀÁÒÉÓ ÃÀáÖÒÅÀ
BEGIN
    EXEC @r = dbo.depo_exec_op_accounting_close
   		@doc_rec_id OUTPUT, 
		@user_id = @user_id, 
		@did = @did, 
		@oid = @oid, 
		@acc_id = @acc_id,
		@dno = @dno, 
		@dt = @dt, 
		@op_type = @op_type, 
		@amount = @amount, 
		@iso = @iso,
		@client_no = @client_no, 
		@dept_no = @dept_no
    IF @@ERROR<>0 OR @r<>0 BEGIN SET @doc_rec_id = 0 RETURN @r END
END

RETURN(0)
GO
