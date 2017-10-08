SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[loan_credit_line_const_op_close]()
RETURNS tinyint AS
BEGIN
	RETURN (255) -- ÃÀáÖÒÅÀ
END
GO
