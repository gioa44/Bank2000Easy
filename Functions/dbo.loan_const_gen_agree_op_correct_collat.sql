SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[loan_const_gen_agree_op_correct_collat]()
RETURNS tinyint AS
BEGIN
	RETURN (60) 
END
GO
