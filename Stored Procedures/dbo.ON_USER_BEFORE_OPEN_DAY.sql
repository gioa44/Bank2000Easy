SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ON_USER_BEFORE_OPEN_DAY]
  @in_tran bit
AS 

--DECLARE
--	@real_date smalldatetime,
--	@bank_open_dt smalldatetime

--SET @real_date = CONVERT(smalldatetime, FLOOR(CONVERT(float, getdate())))
--SET @bank_open_dt = dbo.bank_open_date()

--IF DATEDIFF(DAY, @bank_open_dt, @real_date) > 5
--	RETURN (1)

	--IF dbo.bank_open_date() <= '20110105'
	--	RETURN (1)

RETURN (0)
GO
