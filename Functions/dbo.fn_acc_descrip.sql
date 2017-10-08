SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[fn_acc_descrip] (@acc_usage_type smallint, @acc_usage_descrip varchar(100), @lat int = 0)
RETURNS varchar(100) AS  
BEGIN 
  DECLARE @result varchar(100)

  IF @lat = 0

  SET @result =
    CASE @acc_usage_type 
      WHEN 0 THEN NULL 
      WHEN 1 THEN 'ÌÉÌÃÉÍÀÒÄ' 
      WHEN 2 THEN 'ÁÀÒÀÈÉ' 
      WHEN 3 THEN 'ÊÒÄÃÉÔÉ' 
      WHEN 4 THEN 'ÅÀÃÉÀÍÉ ÀÍÀÁÀÒÉ' 
      WHEN 5 THEN 'ÆÒÃÀÃÉ ÀÍÀÁÀÒÉ' 
      WHEN 6 THEN 'ÛÄÌÍÀáÅÄËÉ' 
      WHEN 7 THEN 'ÅÀÃÉÀÍÉ ÀÍÀÁÀÒÉ +'
	END + 
    CASE 
      WHEN @acc_usage_descrip IS NULL THEN '' ELSE ' (' + @acc_usage_descrip + ')' END

  ELSE

  SET @result =
    CASE @acc_usage_type 
      WHEN 0 THEN NULL 
      WHEN 1 THEN 'Current acc.' 
      WHEN 2 THEN 'Plastic card' 
      WHEN 3 THEN 'Loan' 
      WHEN 4 THEN 'Term Deposit' 
      WHEN 5 THEN 'Increasing Deposit' 
      WHEN 6 THEN 'Savings acc.'
      WHEN 7 THEN 'Term Deposit +'
    END + 
    CASE 
      WHEN @acc_usage_descrip IS NULL THEN '' ELSE ' (' + @acc_usage_descrip + ')' END

  RETURN @result
END
GO
