SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[SWIFT_CHECK_RECEIVER_INSTITUTION]
	@bic_code varchar(11),
	@iso TISO
AS
SET NOCOUNT ON

SELECT B.* 
FROM dbo.BIC_CODES_ B
	INNER JOIN dbo.SWIFT_BIC_CODES S ON B.BIC = S.BIC
WHERE S.BIC=@bic_code AND S.ISO=@iso

RETURN
GO
