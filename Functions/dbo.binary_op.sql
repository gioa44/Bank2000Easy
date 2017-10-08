SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--	& (Bitwise AND)
--	| (Bitwise OR)
--	^ (Bitwise Exclusive OR)
CREATE FUNCTION [dbo].[binary_op] (@bin_1 varbinary(256), @bin_2 varbinary(256), @bin_oper_type char(1))  
RETURNS varbinary(256) AS
BEGIN 
 	DECLARE
		@bin varbinary(256),
		@bin_tmp varbinary(4),
		@bin_len smallint,
		@i smallint
	 
	SET  @bin_len = dbo.max_decimal (len(@bin_1), LEN(@bin_2))
	 
	SET @i = 1
	SET @bin = 0x
	 
	WHILE @i < @bin_len
	BEGIN
	  SET @bin_tmp =
		CASE @bin_oper_type 
			WHEN '&' THEN CAST(SUBSTRING(@bin_1,@i,4) as binary(4)) &  CAST(CAST( SUBSTRING(@bin_2,@i,4) as binary(4)) as int)
			WHEN '|' THEN CAST(SUBSTRING(@bin_1,@i,4) as binary(4)) |  CAST(CAST( SUBSTRING(@bin_2,@i,4) as binary(4)) as int)
			WHEN '^' THEN CAST(SUBSTRING(@bin_1,@i,4) as binary(4)) ^  CAST(CAST( SUBSTRING(@bin_2,@i,4) as binary(4)) as int) 
			ELSE 0 END 
	  SET @bin = @bin + @bin_tmp
	  SET @i = @i + 4
	END
	 
	RETURN(ISNULL(@bin,0))
END
GO
