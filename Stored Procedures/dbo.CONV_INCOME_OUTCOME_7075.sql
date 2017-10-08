SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[CONV_INCOME_OUTCOME_7075] 
	@dt smalldatetime	
AS
DECLARE 
  
  @dept_no int


DECLARE CUR CURSOR FOR
SELECT A.ACC_ID,A.DEPT_NO,
  (ISNULL(A.SALDO,0) + ISNULL(SUM(CASE WHEN D.DEBIT_ID=A.ACC_ID THEN D.AMOUNT ELSE -D.AMOUNT END),0)) AS SALDO
FROM dbo.ACC_VIEW A LEFT OUTER JOIN dbo.OPS_0000 D
   ON D.REC_STATE>=10 AND D.DOC_DATE<=@dt AND (A.ACC_ID=D.DEBIT_ID OR A.ACC_ID=D.CREDIT_ID) AND A.ISO=D.ISO
WHERE (A.BAL_ACC_ALT = 7075) AND A.ISO<>'GEL'-- AND A.SALDO <> $0.00
GROUP BY A.ACC_ID,A.DEPT_NO,A.SALDO
HAVING (ISNULL(A.SALDO,0) + ISNULL(SUM(CASE WHEN D.DEBIT_ID=A.ACC_ID THEN D.AMOUNT ELSE -D.AMOUNT END),0)) <> 0
FOR READ ONLY


DECLARE
	@rec_id_1 int,
	@rec_id_2 int,
	@acc_id_d int,
	@acc_id_c int,
	@branch_id int,
	@r int,
	@counter int,
	@account TACCOUNT,
	@iso TISO,
	@amount TAMOUNT,
	@amount_equ TAMOUNT

SET @counter = 0
 
OPEN CUR
IF @@ERROR <> 0 GOTO ROLLBACK_TRAN

FETCH NEXT FROM CUR INTO @acc_id_d,@dept_no,@amount
IF @@ERROR <> 0 GOTO ROLLBACK_TRAN

BEGIN TRAN
WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT	@account=ACCOUNT, @iso=ISO, @branch_id=BRANCH_ID
	FROM	dbo.ACCOUNTS (NOLOCK)
	WHERE	ACC_ID = @acc_id_d

	
	SET @counter = @counter + 1
	SET @amount_equ = dbo.get_equ(@amount, @iso, @dt)
	SET @acc_id_c = dbo.acc_get_acc_id(@branch_id,@account,'GEL')

	IF @acc_id_c IS NOT NULL
	BEGIN
		PRINT CONVERT(varchar(16), @account) + '/'+ @iso + '  ' + CONVERT(VARCHAR(15), @amount) + ' ËÀÒÉÓ ÀÍÂÀÒÉÛÉ ÀØÅÓ !!!'
		GOTO NextAcc
	END
	ELSE 
		SET @acc_id_c = 8793
		
	IF @amount > $0.00
	BEGIN

		EXEC @r=dbo.ADD_CONV_DOC4 @rec_id_1 OUTPUT,@rec_id_2 OUTPUT,@user_id=10,@owner=10,@dept_no=@dept_no
		,@is_kassa=0,@descrip1='ÊÏÍÅÄÒÓÉÀ (ÂÀÚÉÃÅÀ)',@descrip2='ÊÏÍÅÄÒÓÉÀ (ÚÉÃÅÀ)',@rec_state=20
		,@doc_num=@counter,@op_code='CNVMZ',@doc_date=@dt,@iso_d='GEL',@iso_c=@iso,@amount_d=@amount_equ
		,@amount_c=@amount,@debit_id=@acc_id_c,@credit_id=@acc_id_d,@tariff_kind=0,@info=0,@check_saldo=0
	END
	ELSE
	BEGIN
	SET @amount     = -@amount
	SET @amount_equ = -@amount_equ

		EXEC @r=dbo.ADD_CONV_DOC4 @rec_id_1 OUTPUT,@rec_id_2 OUTPUT,@user_id=10,@owner=10,@dept_no=@dept_no
		,@is_kassa=0,@descrip1='ÊÏÍÅÄÒÓÉÀ (ÂÀÚÉÃÅÀ)',@descrip2='ÊÏÍÅÄÒÓÉÀ (ÚÉÃÅÀ)',@rec_state=20
		,@doc_num=@counter,@op_code='CNVMZ',@doc_date=@dt,@iso_d=@iso,@iso_c='GEL',@amount_d=@amount
		,@amount_c=@amount_equ,@debit_id=@acc_id_d,@credit_id=@acc_id_c,@tariff_kind=0,@info=0,@check_saldo=0

	END
	IF @@ERROR<>0 OR @r <> 0 GOTO ROLLBACK_TRAN
--PRINT CONVERT(varchar(16), @account) + '/'+ @iso + '  ' + CONVERT(VARCHAR(15), @amount) + ' ' + CONVERT(VARCHAR(15), @rec_id_1)
NextAcc:
	FETCH NEXT FROM CUR INTO @acc_id_d,@dept_no,@amount
	IF @@ERROR <> 0 GOTO ROLLBACK_TRAN
END

CLOSE CUR
DEALLOCATE CUR
COMMIT
RETURN

ROLLBACK_TRAN:
IF @@TRANCOUNT>0 ROLLBACK 
CLOSE CUR
DEALLOCATE CUR
GO
