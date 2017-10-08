SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[acc_get_balance2] (
  @acc_id int, 
  @date smalldatetime, 
  @start_balance bit = 0,
  @shadow_level smallint = -1
)

RETURNS @tbl TABLE (BALANCE money, BALANCE_EQU money) AS
BEGIN
	DECLARE @balance money

	SET @balance = dbo.acc_get_balance (@acc_id, @date, @start_balance, 0, @shadow_level)
	
	INSERT INTO @tbl VALUES(@balance, dbo.get_equ(@balance, dbo.acc_get_ccy(@acc_id), @date))
	RETURN
END
GO
