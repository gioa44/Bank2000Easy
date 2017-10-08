SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_fn_const_op_clear_block_amount]()
RETURNS tinyint AS
BEGIN
	RETURN (220) -- ÀÍÀÁÀÒÆÄ ÈÀÍáÉÓ ÁËÏÊÉÓ ÂÀÖØÌÄÁÀ
END
GO
