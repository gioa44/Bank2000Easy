SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE VIEW [dbo].[BC_ACCOUNTS]
AS
SELECT     CC.BC_CLIENT_ID, A.ACCOUNT, A.ISO, A.REC_STATE, A.DESCRIP, A.DESCRIP_LAT, A.CLIENT_NO, A.FLAGS
FROM         dbo.BC_CLIENT_CLIENTS CC INNER JOIN
                      dbo.BC_CLIENTS BC ON CC.BC_CLIENT_ID = BC.BC_CLIENT_ID INNER JOIN
                      dbo.CLIENTS C ON CC.CLIENT_NO = C.CLIENT_NO INNER JOIN
                      dbo.ACCOUNTS A ON C.CLIENT_NO = A.CLIENT_NO


GO