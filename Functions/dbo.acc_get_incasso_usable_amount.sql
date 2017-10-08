SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[acc_get_incasso_usable_amount] (@acc_id int)
RETURNS money
AS
BEGIN
	DECLARE @usable_amount money

	SELECT @usable_amount = - (ISNULL(SALDO, $0) + ISNULL(SHADOW_DBO, $0) - ISNULL(SHADOW_CRO, $0))
	FROM dbo.ACCOUNTS_DETAILS (NOLOCK)
	WHERE ACC_ID = @acc_id

	RETURN @usable_amount
END
GO
