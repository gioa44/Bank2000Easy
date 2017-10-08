SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_GET_LOAN_BAL_ACC]
	@bal_acc TBAL_ACC OUTPUT,
	@client_no int,
	@start_date smalldatetime,
	@end_date smalldatetime,
	@iso TISO,
	@product_id int,
	@check_client_type bit = 0
AS
BEGIN
SET NOCOUNT ON

DECLARE
	@client_type	int,
	@client_subtype	int

DECLARE
	@bal_acc_sub tinyint

SELECT @client_type=CLIENT_TYPE, @client_subtype=CLIENT_SUBTYPE
FROM dbo.CLIENTS (NOLOCK)
WHERE CLIENT_NO = @client_no

IF @client_type IN (2,3,4) AND @client_subtype IS NULL
BEGIN
	RAISERROR ('ÊËÉÄÍÔÉÓ ØÅÄÔÉÐÉ ÀÒ ÀÒÉÓ ÂÀÍÓÀÆÙÅÒÖËÉ, ÓÀÁÀËÀÍÓÏ ÀÍÂÀÒÉÛÉÓ ÃÀÃÂÄÍÀ ÛÄÖÞËÄÁÄËÉÀ!',16,1)
	RETURN(1)
END

IF @check_client_type = 1 
	RETURN 0

SET @bal_acc_sub = 0
SELECT @bal_acc_sub = BAL_ACC_SUB
FROM dbo.LOAN_PRODUCTS (NOLOCK)
WHERE PRODUCT_ID = @product_id

DECLARE
	@bal_acc12	tinyint,
	@bal_acc3	tinyint,
	@bal_acc4	tinyint

IF @client_type = 1
BEGIN
	SET @bal_acc12	= 18
	SET	@bal_acc4 = 1
END
IF @client_type = 2
	SET @bal_acc12	= 12
ELSE
IF @client_type = 3
	SET @bal_acc12	= 13
ELSE
IF @client_type = 4
BEGIN
	SET @bal_acc12	= 18
END
ELSE
IF @client_type = 5
BEGIN
	SET @bal_acc12	= 17
	SET @bal_acc3 = CASE WHEN @iso = 'GEL' THEN 5 ELSE 6 END
	SET	@bal_acc4 = 3
END


IF @client_type IN (2, 3, 4)
	SET @bal_acc4 = @client_subtype

IF @client_type IN (1, 2, 3, 4)
BEGIN
	SET @bal_acc3 = CASE WHEN @iso = 'GEL' THEN 0 ELSE 1 END
	IF DATEADD(yy, 1, @start_date) < @end_date
		SET @bal_acc3 = @bal_acc3 + 5
END

SET @bal_acc = @bal_acc12 * 100 + @bal_acc3 * 10 + @bal_acc4 + CONVERT(money, @bal_acc_sub) / 100

IF NOT EXISTS(SELECT * FROM dbo.PLANLIST_ALT (NOLOCK) WHERE BAL_ACC = @bal_acc AND REC_STATE <> 1)
BEGIN
	DECLARE
		@bal_acc_str varchar(7)
	SET @bal_acc_str = convert(varchar(7), @bal_acc)
	RAISERROR (N'ÓÄÓáÉÓ ÓÀÁÀËÀÍÓÏ "%s" ÀÍÂÀÒÉÛÉ ÀÍÂÀÒÉÛÈÀ ÂÄÂÌÀÛÉ ÀÒ ÌÏÉÞÄÁÍÀ ÀÍ ÃÀáÖÒÖËÉÀ!',16,1,@bal_acc_str)
	RETURN(1)
END

RETURN 0

END



GO
