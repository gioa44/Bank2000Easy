SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[depo_show_depo_ops_transactions]
  @oid int
AS

SET NOCOUNT ON;

DECLARE 
  @dt smalldatetime,
  @docs_rec_id int,
  @did int

SELECT @did = DEPO_ID, @dt = DT, @docs_rec_id = DOC_REC_ID 
FROM dbo.DEPO_OPS 
WHERE OP_ID = @oid

IF @dt < dbo.bank_open_date()
  SELECT DA.* 
  FROM dbo.DOCS_ARC_ALL DA (NOLOCK)
  WHERE DA.DOC_DATE = @dt AND DA.OP_NUM = @docs_rec_id
ELSE
  SELECT DA.* 
  FROM dbo.DOCS_ALL DA (NOLOCK)
  WHERE DA.DOC_DATE = @dt AND DA.OP_NUM = @docs_rec_id
GO
