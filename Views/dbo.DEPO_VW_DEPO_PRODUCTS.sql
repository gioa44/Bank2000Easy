SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DEPO_VW_DEPO_PRODUCTS]
AS
	SELECT P.*
	FROM dbo.DEPO_PRODUCT P (NOLOCK)
GO