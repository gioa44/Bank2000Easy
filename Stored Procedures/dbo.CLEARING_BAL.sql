SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CLEARING_BAL]
	@dt smalldatetime,
	@head_branch_id int
AS

SET NOCOUNT ON

DECLARE
	@d_branch_id int,
	@c_branch_id int,
	@amount money,
	@ccy char(3),
	@d_acc_id int,
	@c_acc_id int,
	@r int,
	@rec_id int

SELECT      
      t2.BRANCH_ID AS D_BRANCH_ID,
      t3.BRANCH_ID AS C_BRANCH_ID,   
      SUM(t1.AMOUNT) AS AMOUNT, 
      t1.ISO AS CCY
INTO #transfers
FROM dbo.OPS_0000 t1
      INNER JOIN dbo.ACCOUNTS t2 ON t1.DEBIT_ID = t2.ACC_ID
      INNER JOIN dbo.ACCOUNTS t3 ON t1.CREDIT_ID = t3.ACC_ID
WHERE t2.BRANCH_ID <> t3.BRANCH_ID AND t1.DOC_DATE = @dt AND t1.DOC_TYPE < 200
GROUP BY t2.BRANCH_ID, t3.BRANCH_ID, t1.ISO

DECLARE cur CURSOR LOCAL FOR
	SELECT D_BRANCH_ID, SUM(AMOUNT), CCY
	FROM #transfers
	GROUP BY D_BRANCH_ID, CCY
	HAVING D_BRANCH_ID <> @head_branch_id
	FOR READ ONLY

OPEN cur

FETCH NEXT FROM cur INTO @d_branch_id, @amount, @ccy

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @d_acc_id = dbo.acc_get_acc_id(@head_branch_id, dbo.get_clearing_account(@d_branch_id, @ccy, 0, 1), @ccy)
	SET @c_acc_id = dbo.acc_get_acc_id(@d_branch_id, dbo.get_clearing_account(@d_branch_id, @ccy, 1, 1), @ccy)

	EXEC @r = dbo._INTERNAL_ADD_DOC
		@rec_id = @rec_id OUTPUT,
		@owner = 3, -- Close day
		@doc_type = 97,
		@doc_date = @dt,
		@iso = @ccy,
		@amount = @amount,
		@doc_num = 1,
		@op_code = '*CLR*',
		@debit_id = @d_acc_id,
		@credit_id = @c_acc_id,
		@rec_state = 20,
		@descrip = 'ÊËÉÒÉÍÂÉ',
		@dept_no = @head_branch_id,
		@channel_id = 0,
		@prod_id = 0,
		@flags = 1

	IF @@ERROR<>0 OR @r<>0 
	BEGIN 
		CLOSE cur
		DEALLOCATE cur

		RETURN 1 
	END

	FETCH NEXT FROM cur INTO @d_branch_id, @amount, @ccy
END

CLOSE cur
DEALLOCATE cur

DECLARE cur2 CURSOR LOCAL FOR
	SELECT C_BRANCH_ID, SUM(AMOUNT), CCY
	FROM #transfers
	GROUP BY C_BRANCH_ID, CCY
	HAVING C_BRANCH_ID <> @head_branch_id
	  FOR READ ONLY

OPEN cur2


FETCH NEXT FROM cur2 INTO @c_branch_id, @amount, @ccy

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @d_acc_id = dbo.acc_get_acc_id(@c_branch_id, dbo.get_clearing_account(@c_branch_id, @ccy, 1, 1), @ccy)
	SET @c_acc_id = dbo.acc_get_acc_id(@head_branch_id, dbo.get_clearing_account(@c_branch_id, @ccy, 0, 1), @ccy)

	EXEC @r = dbo._INTERNAL_ADD_DOC
		@rec_id = @rec_id OUTPUT,
		@owner = 3, -- Close day
		@doc_type = 97,
		@doc_date = @dt,
		@iso = @ccy,
		@amount = @amount,
		@doc_num = 2,
		@op_code = '*CLR*',
		@debit_id = @d_acc_id,
		@credit_id = @c_acc_id,
		@rec_state = 20,
		@descrip = 'ÊËÉÒÉÍÂÉ',
		@dept_no = @head_branch_id,
		@channel_id = 0,
		@prod_id = 0,
		@flags = 1

	IF @@ERROR<>0 OR @r<>0 
	BEGIN 
		CLOSE cur2
		DEALLOCATE cur2

		RETURN 1 
	END

	FETCH NEXT FROM cur2 INTO @c_branch_id, @amount, @ccy
END

CLOSE cur2
DEALLOCATE cur2

DROP TABLE #transfers

RETURN 0
GO
