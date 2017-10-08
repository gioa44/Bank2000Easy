SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[depo_fn_const_op_allow_renew]()
RETURNS tinyint AS
BEGIN
	RETURN (237) -- ÀÍÀÁÀÒÆÄ ÂÀÍÀáËÄÁÉÓ ÃÀÛÅÄÁÀ
END
GO
