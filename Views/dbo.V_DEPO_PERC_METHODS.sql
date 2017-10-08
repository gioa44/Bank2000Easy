SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[V_DEPO_PERC_METHODS]
AS

SELECT M.METHOD_ID, M.METHOD_DESCRIP, D.ISO, D.DAYS, D.PERC
FROM dbo.DEPO_PERC_METHODS M (NOLOCK)  
	INNER JOIN dbo.DEPO_PERC_METHOD_DETAILS D (NOLOCK) ON M.METHOD_ID = D.METHOD_ID
GO