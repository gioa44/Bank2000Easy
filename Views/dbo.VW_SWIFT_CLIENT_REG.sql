SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE VIEW [dbo].[VW_SWIFT_CLIENT_REG]
AS
SELECT C.*
FROM
	dbo.CLIENTS C (NOLOCK)
	INNER JOIN dbo.SWIFT_CLIENT_REG R (NOLOCK) ON C.CLIENT_NO=R.CLIENT_NO
WHERE R.STATE = 0
GO
