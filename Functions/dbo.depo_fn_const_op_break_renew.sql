SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_fn_const_op_break_renew]()
RETURNS tinyint AS
BEGIN
	RETURN (230) -- ÀÍÀÁÀÒÆÄ ÂÀÍÀáËÄÁÀ/ÐÒÏËÏÍÂÀÝÉÉÓ ÛÄßÚÅÄÔÀ
END
GO
