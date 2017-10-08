SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_fn_const_op_withdraw_interest_tax]()
RETURNS tinyint AS
BEGIN
	RETURN (52) -- ÀÍÀÁÀÒÆÄ ÒÄÀËÉÆÄÁÖËÉ ÓÀÒÂÄÁËÉÓ ÃÀÁÄÂÅÒÀ
END
GO
