SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[BCC_EXP_DEPTS]
AS

SET NOCOUNT ON

SELECT DEPT_NO,CODE9,BIC,DESCRIP,DESCRIP_LAT,DATABASE_ID,ALIAS,IS_DEPT
FROM dbo.DEPTS (NOLOCK)
GO
