SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[max_decimal](@a decimal(20,8) , @b decimal(20,8) )
RETURNS decimal(20,8) AS  
BEGIN
	DECLARE @max decimal(20,8) 
 
SET @a = ISNULL(@a, @b)
SET @b = ISNULL(@b, @a)
 
IF @a > @b
   SET @max=@a
ELSE 
  SET @max=@b
 
RETURN(@max)
END
GO
