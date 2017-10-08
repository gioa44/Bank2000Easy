SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[RP_GET_BAL_ACC_TURN]
 @start_date smalldatetime,
 @end_date smalldatetime,
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
FROM dbo.TMP_TURN_DETAILS
WHERE START_DATE = @start_date AND END_DATE = @end_date AND BRANCH_ID = @branch_id 

IF (@@ROWCOUNT = 0)
	TRUNCATE TABLE dbo.TMP_TURNS

IF (@flag & @calc_flags <> @flag)
BEGIN
	IF (@branch_id = -1) --ნაერთი
	BEGIN	
		SET @branch_str = ''
		SELECT @branch_str = @branch_str + CONVERT(varchar(10), DEPT_NO) + ','
		FROM dbo.DEPTS
		SET @branch_str = SUBSTRING(@branch_str, 1, LEN(@branch_str) - 1)
	END	
	ELSE
		SET @branch_str = @branch_id

	CREATE TABLE #turns
		(
			D money NOT NULL,
			C money NOT NULL,
			BAL_ACC decimal(6, 2) PRIMARY KEY
		)

	IF (@flag & 1 <> 0 AND @calc_flags & 1 = 0) -- ლარი
	BEGIN
		EXEC @r = [dbo].[_GET_TURNS_DT_NEW] 
		   @start_date = @start_date
		  ,@end_date = @end_date
		  ,@iso = 'GEL'
		  ,@equ = @equ
		  ,@branch_str = @branch_str
		  ,@shadow_level = default
		  ,@oob = 1 -- ანგარიშგებაში არ შედის გარებალანსური ანგარიშები
		  ,@group_by = default
		  ,@table_name = '#turns'
		
		INSERT INTO dbo.TMP_TURNS
		SELECT BAL_ACC, 'GEL', D, C
		FROM #turns

		IF (@@ERROR <> 0 OR @r <> 0) RETURN -1	
	
		TRUNCATE TABLE #turns
	END
	
	IF (@flag & 2 <> 0 AND @calc_flags & 2 = 0) -- ვალუტა (ჯამურად)
	BEGIN		
		   EXEC @r = [dbo].[_GET_TURNS_DT_NEW] 
		   @start_date = @start_date
		  ,@end_date = @end_date
		  ,@iso = '%%%'
		  ,@equ = @equ
		  ,@branch_str = @branch_str
		  ,@shadow_level = default
		  ,@oob = 1 -- ანგარიშგებაში არ შედის გარებალანსური ანგარიშები
		  ,@group_by = default
		  ,@table_name = '#turns'

		INSERT INTO dbo.TMP_TURNS
		SELECT BAL_ACC, '$$$', D, C
		FROM #turns	

		IF (@@ERROR <> 0 OR @r <> 0) RETURN -1
		
		TRUNCATE TABLE #turns
	END
	
	DROP TABLE #turns

	UPDATE dbo.TMP_TURN_DETAILS
	SET START_DATE = @start_date, END_DATE = @end_date, CALC_FLAGS = @calc_flags | @flag, BRANCH_ID = @branch_id

	IF (@@ROWCOUNT = 0)
		INSERT INTO dbo.TMP_TURN_DETAILS
		VALUES(@start_date, @end_date, @flag, @branch_id)
END

SELECT ISNULL(SUM(DEBIT), $0.000) AS DEBIT, ISNULL(SUM(CREDIT), $0.000) AS CREDIT
FROM dbo.TMP_TURNS
WHERE (BAL_ACC = @bal_acc OR floor(BAL_ACC) = @bal_acc OR floor(BAL_ACC / 10) = @bal_acc OR floor(BAL_ACC / 100) = @bal_acc) AND (ISO = @iso OR @iso = '***')

RETURN (0)
GO
