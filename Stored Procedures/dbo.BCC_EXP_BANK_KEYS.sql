SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[BCC_EXP_BANK_KEYS]
	@branch_id int
AS

SET NOCOUNT ON

SELECT * 
FROM dbo.BC_BANK_KEYS2 (NOLOCK)
WHERE DEPT_NO = @branch_id
GO