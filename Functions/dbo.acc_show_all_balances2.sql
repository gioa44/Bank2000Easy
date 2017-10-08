SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[acc_show_all_balances2] (
  @date smalldatetime, 
  @start_balance bit = 0, 
  @equ bit = 0,
  @shadow_level smallint = -1
)  
RETURNS TABLE AS
RETURN
	SELECT ACC_ID,
			CASE WHEN BALANCE > $0.0000 THEN BALANCE ELSE $0.0000 END AS BALANCE_DEBIT,
			CASE WHEN BALANCE < $0.0000 THEN -BALANCE ELSE $0.000 END AS BALANCE_CREDIT
	FROM dbo.acc_show_all_balances (@date, @start_balance, @equ, @shadow_level)
GO
