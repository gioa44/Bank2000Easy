SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[SYS_BUILD_OPS_HELPER_ARC_TABLE] AS

SET NOCOUNT ON

PRINT 'Rebuilding OPS_HELPER_ARC (OPS_HELPER_XXXX)'

BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE

DELETE FROM dbo.OPS_HELPER_ARC 

INSERT INTO dbo.OPS_HELPER_ARC (ACC_ID, DT, REC_ID)
SELECT DEBIT_ID, DOC_DATE, REC_ID FROM dbo.OPS_ARC
UNION ALL
SELECT CREDIT_ID, DOC_DATE, REC_ID FROM dbo.OPS_ARC

COMMIT
GO
