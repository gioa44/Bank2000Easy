SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[GET_ACC_AVG_SALDO4]
	@acc_id int,
	@start_date smalldatetime,
	@end_date smalldatetime,
	@avg_saldo TAMOUNT OUTPUT,
	@avg_saldo_equ TAMOUNT OUTPUT
AS

SET NOCOUNT ON

DECLARE 
	@iso TISO,
	@dt smalldatetime,
	@acc_open_date smalldatetime

-- To calculate average from DATE_OPEN of ACCOUNT
SET @acc_open_date = @start_date

SELECT @iso = ISO, @acc_open_date = DATE_OPEN 
FROM dbo.ACCOUNTS (NOLOCK)
WHERE ACC_ID = @acc_id

IF @acc_open_date < @start_date 
	SET @dt = @start_date
ELSE 
	SET @dt = @acc_open_date

DECLARE @dates TABLE (DT smalldatetime, PRIMARY KEY ([DT]))

INSERT INTO @dates (DT)
VALUES (@dt)

WHILE @dt < @end_date
BEGIN
	SET @dt = @dt + 1
	INSERT INTO @dates (DT)
	VALUES (@dt)
END

SELECT @avg_saldo = AVG(ISNULL(R.SALDO, $0.0000)), @avg_saldo_equ = AVG( dbo.get_equ(ISNULL(R.SALDO, $0.0000), @iso, T.DT))
FROM @dates T 
	LEFT OUTER JOIN dbo.SALDOS R(NOLOCK) ON R.ACC_ID = @acc_id AND R.DT = 
		(SELECT MAX(DT) FROM dbo.SALDOS RR WHERE RR.ACC_ID = @acc_id AND RR.DT <= T.DT)
GO
