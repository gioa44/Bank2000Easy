SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_show_depo_ops_transactions2]
  @docs_rec_id int,
  @doc_date smalldatetime
AS

SET NOCOUNT ON;

IF @doc_date < dbo.bank_open_date()
  SELECT DA.* 
  FROM dbo.DOCS_ARC_ALL DA (NOLOCK)
  WHERE DA.DOC_DATE = @doc_date AND (DA.REC_ID = @docs_rec_id OR DA.OP_NUM = @docs_rec_id)
ELSE
  SELECT DA.* 
  FROM dbo.DOCS_ALL DA (NOLOCK)
  WHERE DA.DOC_DATE = @doc_date AND (DA.REC_ID = @docs_rec_id OR DA.OP_NUM = @docs_rec_id)
GO
