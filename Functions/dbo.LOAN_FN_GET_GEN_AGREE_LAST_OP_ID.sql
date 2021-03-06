SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE FUNCTION [dbo].[LOAN_FN_GET_GEN_AGREE_LAST_OP_ID](@credit_line_id int)
RETURNS int
AS
BEGIN
	DECLARE
		@last_op_id int

	SELECT @last_op_id = MAX(OP_ID)
	FROM dbo.LOAN_GEN_AGREE_OPS (NOLOCK)
	WHERE CREDIT_LINE_ID = @credit_line_id

	RETURN @last_op_id
END
GO
