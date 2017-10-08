SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/* This is only an example for JOBS */
CREATE PROCEDURE [dbo].[JOB_EXAMPLE]
  @acc_id int
AS

DECLARE @saldo TAMOUNT

SET @saldo = -
   (SELECT ISNULL(SALDO,0) + ISNULL(SHADOW_DBO,0) - ISNULL(SHADOW_CRO,0) 
    FROM dbo.ACCOUNTS_DETAILS
    WHERE ACC_ID = @acc_id)

IF @saldo < 0 
BEGIN
	DECLARE @account TACCOUNT, @iso TISO
	SELECT @account = ACCOUNT, @iso = ISO
	FROM dbo.ACCOUNTS
	WHERE ACC_ID = @acc_id

	INSERT INTO dbo.TODO ([USER_ID],DATE_AND_TIME,DESCRIP,ORIGINATOR)
	VALUES (10,GetDate()+1,'ÀÍÂÀÒÉÛÉ ' + LTRIM(STR(@account)) + '/' + @iso + ' ÂÀÅÉÃÀ ßÉÈÄËÆÄ. ÛÄÀÌÏßÌÄ',2)
END

RETURN 0
GO
