SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[SWIFT_CHECK_REFNUM] (@ref_num varchar(32), @dt smalldatetime)
RETURNS bit
AS
BEGIN 
  DECLARE @exists bit

  SET @dt = DATEADD(mm, -1, @dt)

  SET @exists =
    CASE 
      WHEN EXISTS(SELECT * FROM dbo.SWIFT_DOCS (NOLOCK) WHERE REF_NUM=@ref_num) THEN 1
      WHEN EXISTS(SELECT * FROM dbo.SWIFT_DOCS_ARC (NOLOCK) WHERE REF_NUM=@ref_num AND DOC_DATE > @dt) THEN 1
      ELSE 0
    END 
  
  RETURN(@exists)
END

GO
