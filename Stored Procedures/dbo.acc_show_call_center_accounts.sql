SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[acc_show_call_center_accounts]
	@client_no int
AS

SET NOCOUNT ON

SELECT * 
FROM dbo.C_ACCOUNTS A (NOLOCK)
WHERE CLIENT_NO = @client_no AND FLAGS & 16 <> 0
GO