SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CHECK_SAXAZCODE] (@saxazkod varchar(9), @receiver_acc TINTACCOUNT, @descrip varchar(150) OUTPUT, @saxaz_descrip varchar(255) OUTPUT) AS

SET NOCOUNT ON

SET @descrip = NULL

IF NOT (EXISTS(SELECT * FROM dbo.SAXAZCODES9 (NOLOCK) WHERE SAXAZKOD = @saxazkod))
BEGIN
  SET @descrip = 'ÓÀáÀÆÉÍÏ ÊÏÃÉ ÀÒ ÌÏÉÞÄÁÍÀ' 
  RETURN (1) 
END
ELSE
BEGIN
  SELECT @descrip = S4.DESCRIP
  FROM dbo.SAXAZCODES_4 S4 (NOLOCK) 
  WHERE S4.[ID] = convert(smallint,SUBSTRING(@saxazkod, 6, 4))
  
  SELECT @saxaz_descrip = 'ÁÉÖãÄÔÉÓ ÛÄÌÏÓÖËÏÁÄÁÉÓ ÄÒÈÉÀÍÉ ÀÍÂÀÒÉÛÉ (' + S1.DESCRIP + '/' + S3.DESCRIP + ')'
  FROM dbo.SAXAZCODES9 S9 (NOLOCK) 
    INNER JOIN dbo.SAXAZCODES_1 S1 (NOLOCK) ON convert(tinyint,SUBSTRING(S9.SAXAZKOD,1,1)) = S1.[ID] 
    INNER JOIN dbo.SAXAZCODES_3 S3 (NOLOCK) ON convert(smallint,SUBSTRING(S9.SAXAZKOD,3,3)) = S3.[ID] 
  WHERE S9.SAXAZKOD = @saxazkod
END

RETURN (0)
GO
