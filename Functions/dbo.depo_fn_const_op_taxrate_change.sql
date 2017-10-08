SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_fn_const_op_taxrate_change]()
RETURNS tinyint AS
BEGIN
	RETURN (112) -- დაბეგვრის საპროცენტო სარგებლის შეცვლა
END
GO
