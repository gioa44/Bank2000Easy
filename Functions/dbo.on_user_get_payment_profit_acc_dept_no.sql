SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[on_user_get_payment_profit_acc_dept_no] (@user_id int, @dept_no int, @acc_id int)
RETURNS int AS
BEGIN
  RETURN @dept_no
END
GO
