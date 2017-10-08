SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_fn_const_op_shareable_change]()
RETURNS tinyint AS
BEGIN
	RETURN (140) -- ÀÍÀÁÀÒÆÄ ÈÀÍÀÌ×ËÏÁÄËÏÁÉÓ ÛÄÝÅËÀ
END
GO
