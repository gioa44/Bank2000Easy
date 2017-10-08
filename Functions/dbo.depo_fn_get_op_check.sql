SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_fn_get_op_check](@depo_id int)
RETURNS 
  @DEPO_CHECK TABLE (
    [START_DATE]  smalldatetime,
    END_DATE  smalldatetime,
    DISBURSEMENT_DATE  smalldatetime,
    LAST_OP_DATE  smalldatetime)
AS
BEGIN
	DECLARE
		@last_op_id int,
		@start_date smalldatetime,
		@close_date smalldatetime,
		@last_op_date smalldatetime

	SET @last_op_id = dbo.depo_fn_get_last_op_id(@depo_id)
  
	SELECT @start_date = [START_DATE], @close_date = END_DATE
	FROM dbo.DEPO_DEPOSITS
	WHERE DEPO_ID = @depo_id
  
	SELECT @last_op_date = OP_DATE
	FROM dbo.DEPO_OP
	WHERE OP_ID = @last_op_id

  INSERT INTO @DEPO_CHECK([START_DATE], END_DATE, LAST_OP_DATE)
  VALUES(@start_date,  @close_date,  @last_op_date)
RETURN
END
GO
