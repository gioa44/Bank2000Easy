SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[BCC_EXP_CLIENT_REL_TYPES]
AS
SET NOCOUNT ON

SELECT * FROM dbo.CLIENT_RELATION_TYPES
GO