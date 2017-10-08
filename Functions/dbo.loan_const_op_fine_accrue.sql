SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[loan_const_op_fine_accrue]()
RETURNS tinyint AS
BEGIN
	RETURN (230) -- ÓÄÓáÆÄ ÓÀÖÒÀÅÉÓ ÃÀÒÉÝáÅÀ
END
GO
