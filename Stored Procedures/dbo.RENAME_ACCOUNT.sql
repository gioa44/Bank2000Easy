SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[RENAME_ACCOUNT] (@acc_id int, @new_account TACCOUNT)
AS
SET NOCOUNT ON

DECLARE @old_account TACCOUNT
  
SELECT @old_account = ACCOUNT 
FROM dbo.ACCOUNTS (NOLOCK)
WHERE ACC_ID = @acc_id

IF @old_account IS NULL
BEGIN
  RAISERROR ('Account not found', 16, 1)
  RETURN (1)
END

UPDATE dbo.ACCOUNTS
SET ACCOUNT = @new_account
WHERE ACC_ID = @acc_id
GO
