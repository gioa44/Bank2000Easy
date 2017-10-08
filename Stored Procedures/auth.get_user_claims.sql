SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROCEDURE [auth].[get_user_claims] (@sessionId [nchar] (36), @isClientManager [bit] OUTPUT, @isOperatorCashier [bit] OUTPUT, @isAccManager [bit] OUTPUT, @isCallCenterOperator [bit] OUTPUT, @isCashier [bit] OUTPUT, @isLoanOfficer [bit] OUTPUT, @isDepoManager [bit] OUTPUT)
WITH EXECUTE AS CALLER
AS EXTERNAL NAME [AltaSoft.Authentication].[AltaSoft.Authentication.AuthenticationFactory].[GetUserClaims]
GO
