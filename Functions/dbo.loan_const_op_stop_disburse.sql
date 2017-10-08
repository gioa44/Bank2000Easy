SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[loan_const_op_stop_disburse]()
RETURNS tinyint AS
BEGIN
	RETURN (65) -- ÓÀÓÄÓáÏ ÈÀÍáÉÓ ÀÈÅÉÓÄÁÉÓ ÛÄßÚÅÄÔÀ
END
GO
