SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[VAL_RATES] AS

SELECT * FROM dbo.VAL_RATES_0000 (NOLOCK)
  UNION ALL
GO