SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[BCC_CHECK_SAXAZCODE] (@saxazkod varchar(9), @receiver_acc varchar(34), @lat bit = 0, @descrip varchar(150) OUTPUT, @saxaz_descrip varchar(255) OUTPUT) AS
  
SET NOCOUNT ON

DECLARE 
  @r int

  IF LTRIM(ISNULL(@saxazkod, '')) = ''
  BEGIN
    IF @lat = 0 
         RAISERROR ('<ERR>ÓÀáÀÆÉÍÏ ÊÏÃÉ ÀÒ ÀÒÉÓ ÛÄÅÓÄÁÖËÉ</ERR>',16,1)
    ELSE RAISERROR ('<ERR>Treasury code is empty</ERR>',16,1)
    RETURN (1009)
  END

EXEC @r = dbo.CHECK_SAXAZCODE @saxazkod, @receiver_acc, @descrip OUTPUT, @saxaz_descrip OUTPUT
IF @r = 0 RETURN (0)

IF @r = 1
BEGIN
  IF @lat = 0 
       RAISERROR('<ERR>ÓÀáÀÆÉÍÏ ÊÏÃÉ "%s" ÀÒ ÌÏÉÞÄÁÍÀ</ERR>',16,1,@saxazkod)
  ELSE RAISERROR('<ERR>Treasury code %s not found</ERR>',16,1,@saxazkod);
END
ELSE
BEGIN
  IF @lat = 0 
       RAISERROR('<ERR>ÀÒÀÓßÏÒÉ ÓÀáÀÆÉÍÏ ÊÏÃÉ "%s"</ERR>',16,1,@saxazkod)
  ELSE RAISERROR('<ERR>Incorrect Treasury code %s</ERR>',16,1,@saxazkod);
END

RETURN (@r)
GO
