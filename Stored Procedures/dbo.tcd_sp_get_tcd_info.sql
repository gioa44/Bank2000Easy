SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tcd_sp_get_tcd_info]
AS
BEGIN
	SELECT DISTINCT D.DEPT_NO, D.DESCRIP FROM dbo.DEPTS D 
	WHERE D.DEPT_NO IN (SELECT DISTINCT T.DEPT_NO FROM dbo.TCDS T)		
END
GO
