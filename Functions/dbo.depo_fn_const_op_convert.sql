SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_fn_const_op_convert]()
RETURNS tinyint AS
BEGIN
	RETURN (160) -- ÀÍÀÁÒÉÓ ÊÏÍÅÄÒÔÉÒÄÁÀ
END
GO
