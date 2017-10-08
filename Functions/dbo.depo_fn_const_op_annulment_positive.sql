SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_fn_const_op_annulment_positive]()
RETURNS tinyint AS
BEGIN
	RETURN (245) -- ÀÍÀÁÒÉÓ ÃÀÒÙÅÄÅÀ (ÐÏÆÉÔÉÅÉ)
END
GO
