SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[BCC_EXP_COUNTRIES]
AS

SET NOCOUNT ON

SELECT COUNTRY, DESCRIP, ZONE_TYPE 
FROM dbo.COUNTRIES
GO