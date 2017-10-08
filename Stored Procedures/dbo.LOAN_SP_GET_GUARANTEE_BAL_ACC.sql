SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[LOAN_SP_GET_GUARANTEE_BAL_ACC]
	@bal_acc TBAL_ACC OUTPUT,
	@client_no int,
	@iso TISO
AS
SET NOCOUNT ON

DECLARE
	@client_type int,
	@client_subtype int,
	@bal_acc_sub1 tinyint,
	@bal_acc_sub2 tinyint

SELECT 
	@client_type = CLIENT_TYPE, 
	@client_subtype = CLIENT_SUBTYPE
FROM dbo.CLIENTS (NOLOCK)
WHERE CLIENT_NO = @client_no

SET @bal_acc = $502.00

IF @iso = 'GEL'
	SET @bal_acc_sub1 = 0
ELSE
	SET @bal_acc_sub1 = 1

IF @client_type = 1
	SET @bal_acc_sub2 = 1
ELSE 
IF (@client_type IN (3, 4)) AND (@client_subtype IN (2, 3, 4, 5, 6, 7))
	SET @bal_acc_sub2 = @client_subtype
ELSE SET @bal_acc_sub2 = 8

SET @bal_acc = @bal_acc + CONVERT(money, @bal_acc_sub1) / 10 + CONVERT(money, @bal_acc_sub2) / 100

IF @bal_acc IS NULL
BEGIN
	RAISERROR (N'ÂÀÒÀÍÔÉÉÓ ÓÀÁÀËÀÍÓÏ ÀÍÂÀÒÉÛÉÓ ÃÀÃÂÄÍÀ ÅÄÒ áÄÒáÃÄÁÀ!',16,1)
	RETURN(1)
END

IF NOT EXISTS(SELECT * FROM dbo.PLANLIST_ALT (NOLOCK) WHERE BAL_ACC = @bal_acc AND REC_STATE <> 1)
BEGIN
	DECLARE
		@bal_acc_str varchar(7)
	SET @bal_acc_str = convert(varchar(7), @bal_acc)
	RAISERROR (N'ÂÀÒÀÍÔÉÉÓ ÓÀÁÀËÀÍÓÏ "%s" ÀÍÂÀÒÉÛÉ ÀÍÂÀÒÉÛÈÀ ÂÄÂÌÀÛÉ ÀÒ ÌÏÉÞÄÁÍÀ ÀÍ ÃÀáÖÒÖËÉÀ!',16,1,@bal_acc_str)
	RETURN(2)
END

RETURN 0

GO
