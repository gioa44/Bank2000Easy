SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[auth_get_user_claims]
	@sessionId [char](36),
	@isClientManager [bit] OUTPUT,
	@isOperatorCashier [bit] OUTPUT,
	@isAccManager [bit] OUTPUT,
	@isCallCenterOperator [bit] OUTPUT,
	@isCashier [bit] OUTPUT,
	@isLoanOfficer [bit] OUTPUT,
	@isDepoManager [bit] OUTPUT
AS
	DECLARE @r int
	EXEC @r = auth.[get_user_claims]
		@sessionId,
		@isClientManager OUTPUT,
		@isOperatorCashier OUTPUT,
		@isAccManager OUTPUT,
		@isCallCenterOperator OUTPUT,
		@isCashier OUTPUT,
		@isLoanOfficer OUTPUT,
		@isDepoManager OUTPUT
	RETURN @r
GO
