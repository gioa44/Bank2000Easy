SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[BCC_EXP_ACC_PRODUCTS_FILTER]
AS
SET NOCOUNT ON

SELECT * FROM dbo.ACC_PRODUCTS_FILTER
GO