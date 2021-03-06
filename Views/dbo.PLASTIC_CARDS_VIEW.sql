SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  VIEW [dbo].[PLASTIC_CARDS_VIEW]
AS
SELECT			P.*, E.DESCRIP AS DEPT_NAME, C.DESCRIP AS CARD_TYPE_NAME
FROM         dbo.PLASTIC_CARDS AS P INNER JOIN
                      dbo.DEPTS AS E ON E.DEPT_NO = P.DEPT_NO INNER JOIN
                      dbo.CCARD_TYPES AS C ON C.REC_ID = P.CARD_TYPE

GO
