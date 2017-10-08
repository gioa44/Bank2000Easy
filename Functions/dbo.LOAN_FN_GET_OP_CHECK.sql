SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[LOAN_FN_GET_OP_CHECK](@loan_id int)
RETURNS 
  @LOAN_CHECK TABLE (
    START_DATE  smalldatetime,
    CLOSE_DATE  smalldatetime,
    DISBURSEMENT_DATE  smalldatetime,
    LAST_OP_DATE  smalldatetime)
AS
BEGIN
	DECLARE
		@last_oid int,
		@start_date smalldatetime,
		@close_date smalldatetime,
		@disbursement_date smalldatetime,
		@last_op_date smalldatetime

	SET @last_oid=dbo.LOAN_FN_GET_LAST_OP_ID(@loan_id)
  
	SELECT @start_date = START_DATE, @close_date = END_DATE FROM dbo.LOANS WHERE LOAN_ID = @loan_id
  
	SELECT @disbursement_date = OP_DATE FROM dbo.LOAN_OPS WHERE (LOAN_ID = @loan_id) AND (OP_TYPE IN (50, 210))
	SELECT @last_op_date = OP_DATE FROM dbo.LOAN_OPS WHERE OP_ID=@last_oid

  INSERT INTO @LOAN_CHECK
  (START_DATE, CLOSE_DATE, DISBURSEMENT_DATE, LAST_OP_DATE)
  VALUES
  (@start_date,  @close_date,  @disbursement_date,  @last_op_date)
RETURN
END
GO
