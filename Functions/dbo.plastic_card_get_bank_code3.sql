SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[plastic_card_get_bank_code3](@client_no int)
RETURNS smallint
BEGIN
	DECLARE
		@result smallint,
		@dept_no int

	SELECT	@dept_no = dbo.acc_get_dept_no(ACC_ID)
	FROM dbo.PLASTIC_CARD_ACCOUNTS_FOR_SEND
	WHERE CLIENT_NO = @client_no

	SELECT @result = CONVERT(smallint, SUBSTRING(CONVERT(VARCHAR(9), CODE9), 7, 3)) FROM DEPTS
	WHERE DEPT_NO = @dept_no

	RETURN @result

END
GO
