SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[PROCESS_DEB_ACCRUALS]
	@user_id int,
	@dept_no int,
	@doc_date smalldatetime,
	@calc_date smalldatetime,
	@force_calc bit = 0
AS

DECLARE @acc_id int

DECLARE cc CURSOR FAST_FORWARD READ_ONLY LOCAL
FOR 
SELECT P.ACC_ID
FROM dbo.ACCOUNTS_DEB_PERC P 
	INNER JOIN dbo.ACCOUNTS A ON A.ACC_ID = P.ACC_ID
WHERE  A.REC_STATE NOT IN (2, 64, 128) AND
	P.START_DATE <= @calc_date AND ((P.END_DATE IS NULL OR P.END_DATE >= @calc_date) OR 
	(P.END_DATE < @calc_date AND DAY(@calc_date + 1) = 1 AND MONTH(P.END_DATE) = MONTH(@calc_date) AND YEAR(P.END_DATE) = YEAR(@calc_date)))

OPEN cc
FETCH NEXT FROM cc INTO @acc_id
WHILE @@FETCH_STATUS = 0
BEGIN

	EXEC dbo.PROCESS_ACCRUAL
		@perc_type = 1,
		@acc_id = @acc_id,
		@user_id = @user_id,
		@dept_no = @dept_no,
		@doc_date = @doc_date,
		@calc_date = @calc_date,
		@force_calc = @force_calc,
		@force_realization = 0,
		@simulate = 0

	FETCH NEXT FROM cc INTO @acc_id
END

CLOSE cc
DEALLOCATE cc
GO
