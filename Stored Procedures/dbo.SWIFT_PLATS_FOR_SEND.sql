SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[SWIFT_PLATS_FOR_SEND]
  @dt smalldatetime,
  @old_plats bit = 0
AS

SET NOCOUNT ON

DECLARE @corr_account_va TACCOUNT

EXEC GET_SETTING_ACC 'CORR_ACC_VA', @corr_account_va OUTPUT

SELECT * FROM DOCS_VALPLAT
WHERE (REC_STATE BETWEEN 10 AND 19) AND --(CREDIT = @corr_account_va) AND 
      ((@old_plats = 0 AND DOC_DATE = @dt) OR (@old_plats <> 0 AND DOC_DATE <= @dt))
GO
