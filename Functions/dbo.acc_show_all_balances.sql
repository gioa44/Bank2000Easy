SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[acc_show_all_balances] (
  @date smalldatetime, 
  @start_balance bit = 0, 
  @equ bit = 0,
  @shadow_level smallint = -1
)  
RETURNS TABLE AS
RETURN
	SELECT ACC_ID, dbo.acc_get_balance(ACC_ID, @date, @start_balance, @equ, @shadow_level) AS BALANCE 
	FROM dbo.ACCOUNTS (NOLOCK)
GO
