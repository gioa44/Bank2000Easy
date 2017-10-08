SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[acc_get_acc_id] (@branch_id int, @account TACCOUNT, @ccy TISO)  
RETURNS int AS  
BEGIN 
  RETURN (SELECT ACC_ID FROM dbo.ACCOUNTS (NOLOCK) WHERE ACCOUNT = @account AND ISO = @ccy AND BRANCH_ID = @branch_id)
END
GO
