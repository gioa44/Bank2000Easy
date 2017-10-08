SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ON_USER_AFTER_LOAN_SP_COLLECTION_CLIENT_AMOUNT]
	@user_id int,
	@date smalldatetime,
	@loan_id int,
	@iso TISO,
	@acc_id int,
	@client_no int,
	@debt_amount money,
	@simulate bit,
	@client_amount money
AS
SET NOCOUNT ON;
RETURN 0

GO
