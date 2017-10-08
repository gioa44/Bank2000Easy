SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[acc_is_incasso](@account TACCOUNT, @iso TISO)
RETURNS bit
BEGIN
	DECLARE
		@client_no int,
		@client_rec_state int,
		@result bit

	SELECT	@client_no = CLIENT_NO
	FROM dbo.ACCOUNTS
	WHERE ACCOUNT = @account AND ISO = @iso AND REC_STATE = 16

	SET @result = ISNULL(@client_no, 0)

	IF @result > 0
	BEGIN
		SELECT	@client_rec_state = REC_STATE
		FROM dbo.CLIENTS
		WHERE CLIENT_NO = @client_no AND REC_STATE = 4

		IF ISNULL(@client_rec_state, 0) > 0
			SET @result = 1
		ELSE
			SET @result = 0
	END

	RETURN ISNULL(@result, $0)

END
GO
