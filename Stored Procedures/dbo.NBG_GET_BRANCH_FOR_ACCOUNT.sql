SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[NBG_GET_BRANCH_FOR_ACCOUNT]
	@bank_code TINTBANKCODE, 
	@account varchar(16) = null
AS

SET NOCOUNT ON;

EXEC dbo.GET_BRANCH_FOR_ACCOUNT @bank_code OUTPUT, @account, 'GEL'

SELECT @bank_code AS BANK_CODE
GO
