SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[acc_get_act_pas] (@acc_id int)  
RETURNS tinyint AS  
BEGIN 
  RETURN (SELECT ACT_PAS FROM dbo.ACCOUNTS (NOLOCK) WHERE ACC_ID = @acc_id)
END
GO
