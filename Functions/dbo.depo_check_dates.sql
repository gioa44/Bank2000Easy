SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_check_dates] (@did int)
RETURNS 
	@tbl TABLE (
		START_DATE        smalldatetime NOT NULL,
		END_DATE          smalldatetime NOT NULL,
		ACTIVE_DATE       smalldatetime,
		LAST_OP_DATE      smalldatetime,
		LAST_AUTO_OP_DATE smalldatetime)
AS
BEGIN

	DECLARE @oid int

	SET @oid = dbo.depo_get_last_op_id (@did)

	DECLARE 
		@start_date smalldatetime,
		@end_date smalldatetime,
		@active_date smalldatetime,
		@last_op_date smalldatetime,
		@last_auto_op_date smalldatetime,
		@acc_id int

	SELECT @acc_id = ACC_ID, @start_date = D.START_DATE, @end_date = O.END_DATE, @active_date = D.START_DATE 
	FROM dbo.DEPOS D
		INNER JOIN dbo.DEPO_DATA O ON O.OP_ID = D.OP_ID 
	WHERE D.DEPO_ID = @did AND O.OP_ID = @oid

	SELECT @last_op_date = O.DT
	FROM dbo.DEPO_OPS O 
	WHERE O.OP_ID = @oid

	SELECT @last_auto_op_date = P.LAST_CALC_DATE
	FROM dbo.ACCOUNTS_CRED_PERC P
	WHERE P.ACC_ID = @acc_id
	
	IF @last_auto_op_date IS NULL
		SET @last_auto_op_date = @last_op_date

	INSERT INTO @tbl (START_DATE, END_DATE, ACTIVE_DATE, LAST_OP_DATE, LAST_AUTO_OP_DATE)
	VALUES (@start_date,  @end_date,  @active_date,  @last_op_date, @last_auto_op_date)
	
	RETURN
END
GO
