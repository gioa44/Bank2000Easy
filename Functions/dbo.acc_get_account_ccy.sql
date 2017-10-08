SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[acc_get_account_ccy] (@acc_id int)  
RETURNS varchar(40) AS  
BEGIN 
  RETURN (SELECT CONVERT(varchar(20),ACCOUNT) + '/' + ISO FROM dbo.ACCOUNTS (NOLOCK) WHERE ACC_ID = @acc_id)
END
GO