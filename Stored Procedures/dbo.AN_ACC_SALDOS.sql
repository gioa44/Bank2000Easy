SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[AN_ACC_SALDOS]
  @account 	TACCOUNT,
  @iso		TISO,
  @start_date	smalldatetime,
  @end_date	smalldatetime
AS

SET NOCOUNT ON

declare 
  @dt smalldatetime

SET @dt = @start_date
SELECT @dt AS DT into #TempDT

WHILE @dt < @end_date
BEGIN
 SET @dt = @dt + 1
 INSERT INTO #TempDT (DT) values (@dt)
END

SELECT T.DT,ISNULL(R.AMOUNT,0) AS SALDO
FROM #TempDT T 
LEFT OUTER JOIN SALDOS R ON
  R.ACCOUNT=@account AND R.ISO = @iso AND R.DT = 
    (SELECT MAX(DT) FROM SALDOS RR WHERE RR.ACCOUNT=@account AND RR.ISO = @iso AND RR.DT <= T.DT)

drop table #TempDT


GO
