SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[RP_GET_BAL_ACC_BALANCE_OOB]
 @dt smalldatetime,
 @bal_acc TBAL_ACC,	
 @equ bit = 0,
 @branch_id int = -1,
 @dept_no int = NULL,
 @iso TISO = NULL 
AS
DECLARE 
	@branch_str varchar(255),
	@flag int,
	@calc_flags int,
	@r int

SET @flag = CASE 
				WHEN @iso = 'GEL' THEN 1 
				WHEN @iso = '$$$' THEN 2
				WHEN @iso = '***' THEN 3
			ELSE	
				4
			END
SET @equ = ISNULL(@equ, 0)
SET @calc_flags = 0

SELECT @calc_flags = CALC_FLAGS
FROM dbo.TMP_BALANCE_DETAILS_OOB 
WHERE CALC_DATE = @dt AND BRANCH_ID = @branch_id 

IF (@@ROWCOUNT = 0)
	TRUNCATE TABLE dbo.TMP_BALANCES_OOB

IF (@flag & @calc_flags <> @flag)
BEGIN
	IF (@branch_id = -1) --??????
	BEGIN	
		SET @branch_str = ''
		SELECT @branch_str = @branch_str + CONVERT(varchar(10), DEPT_NO) + ','
		FROM dbo.DEPTS
		SET @branch_str = SUBSTRING(@branch_str, 1, LEN(@branch_str) - 1)
	END	
	ELSE
		SET @branch_str = @branch_id

	CREATE TABLE #balances
		(
			DBS money NOT NULL,
			CRS money NOT NULL,
			BAL_ACC decimal(6, 2) PRIMARY KEY
		)
	
	IF (@flag & 1 <> 0 AND @calc_flags & 1 = 0) -- ????
	BEGIN
		EXEC @r = [dbo].[_GET_BALANCE_DT_NEW] 
		   @start_balance = 0
		  ,@dt = @dt
		  ,@iso = 'GEL'
		  ,@equ = @equ
		  ,@branch_str = @branch_str
		  ,@shadow_level = default
		  ,@oob = 2 -- ????????????? ??????????
		  ,@group_by = default
		  ,@table_name = '#balances'

		INSERT INTO dbo.TMP_BALANCES_OOB
		SELECT BAL_ACC, 'GEL', DBS, CRS
		FROM #balances

		IF (@@ERROR <> 0 OR @r <> 0) RETURN -1	
	
		TRUNCATE TABLE #balances
	END
	
	IF (@flag & 2 <> 0 AND @calc_flags & 2 = 0) -- ?????? (???????)
	BEGIN
		EXEC @r = [dbo].[_GET_BALANCE_DT_NEW] 
		   @start_balance = 0
		  ,@dt = @dt
		  ,@iso = '%%%'
		  ,@equ = @equ
		  ,@branch_str = @branch_str
		  ,@shadow_level = default
		  ,@oob = 2 -- ????????????? ??????????
		  ,@group_by = default
		  ,@table_name = '#balances'

		INSERT INTO dbo.TMP_BALANCES_OOB
		SELECT BAL_ACC, '$$$', DBS, CRS
		FROM #balances

		IF (@@ERROR <> 0 OR @r <> 0) RETURN -1
		
		TRUNCATE TABLE #balances
	END
	
	DROP TABLE #balances

	UPDATE dbo.TMP_BALANCE_DETAILS_OOB
	SET CALC_DATE = @dt, CALC_FLAGS = @calc_flags | @flag, BRANCH_ID = @branch_id

	IF (@@ROWCOUNT = 0)
		INSERT INTO dbo.TMP_BALANCE_DETAILS_OOB
		VALUES(@dt, @flag, @branch_id)
END		

SELECT ISNULL(SUM(DEBIT), $0.000) AS DEBIT, ISNULL(SUM(CREDIT), $0.000) AS CREDIT, ISNULL(SUM(DEBIT - CREDIT), $0.000) AS BALANCE
FROM dbo.TMP_BALANCES_OOB
WHERE (BAL_ACC = @bal_acc OR floor(BAL_ACC) = @bal_acc OR floor(BAL_ACC / 10) = @bal_acc) AND (ISO = @iso OR @iso = '***')

RETURN 0
GO
