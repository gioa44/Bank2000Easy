SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[acc_get_dept_no] (@acc_id int)  
RETURNS int AS  
BEGIN 
  RETURN (SELECT DEPT_NO FROM dbo.ACCOUNTS (NOLOCK) WHERE ACC_ID = @acc_id)
END
GO
