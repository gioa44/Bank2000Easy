SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[dx_fn_get_intrate] (@formula varchar(100))
RETURNS money
AS
BEGIN
--CASE WHEN AMOUNT<-0 THEN AMOUNT*-10.4 ELSE 0 END 34
  DECLARE @int_rate money
  SET @int_rate = convert(money, SUBSTRING(@formula, 34, 2))
  RETURN @int_rate  
END

GO
