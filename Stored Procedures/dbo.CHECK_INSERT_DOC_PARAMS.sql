SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CHECK_INSERT_DOC_PARAMS]
  @debit TACCOUNT,
  @credit TACCOUNT,
  @iso TISO
AS

SET NOCOUNT ON

  DECLARE @s varchar(1000)

  IF NOT EXISTS(SELECT * FROM dbo.ACCOUNTS (NOLOCK) WHERE ACCOUNT=@debit AND ISO=@iso)
  BEGIN 
    SET @s = 'ÃÄÁÄÔÉÓ ÀÍÂÀÒÉÛÉ ' + ISNULL(CONVERT(varchar(20), @debit), '(null)') + '/' + @iso + ' ÀÒ ÌÏÉÞÄÁÍÀ.'
    RAISERROR (@s, 16, 1)
  END
  
  IF NOT EXISTS(SELECT * FROM dbo.ACCOUNTS (NOLOCK) WHERE ACCOUNT=@credit AND ISO=@iso)
  BEGIN 
    SET @s = 'ÊÒÄÃÉÔÉÓ ÀÍÂÀÒÉÛÉ ' + ISNULL(CONVERT(varchar(20), @credit), '(null)') + '/' + @iso + ' ÀÒ ÌÏÉÞÄÁÍÀ.'
    RAISERROR (@s, 16, 1)
  END

  IF @credit = @debit
  BEGIN 
    SET @s = 'ÃÄÁÄÔÉÓ ÃÀ ÊÒÄÃÉÔÉÓ ÀÍÂÀÒÉÛÉ ÄÒÈÍÀÉÒÉÀ: ' + ISNULL(CONVERT(varchar(20), @debit), '(null)') + '/' + @iso
    RAISERROR (@s, 16, 1)
  END
GO
