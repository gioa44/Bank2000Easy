SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[acc_get_name2] (@account TACCOUNT, @ccy TISO)
RETURNS varchar(100) AS  
BEGIN 
  RETURN (SELECT DESCRIP FROM dbo.ACCOUNTS (NOLOCK) WHERE ACCOUNT = @account AND ISO = @ccy)
END
GO
