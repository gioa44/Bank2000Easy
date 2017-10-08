SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[_GET_OPERATION_4LIST]
  @rec_ids_str varchar(1000)
AS

SET NOCOUNT ON

SELECT D.REC_ID, D.OP_CODE, D.DEBIT, D.CREDIT, D.ISO, D.AMOUNT, D.DESCRIP, D.DOC_DATE, D.DOC_TYPE
FROM dbo.DOCS (NOLOCK) D
	INNER JOIN dbo.fn_split_list_int(@rec_ids_str, ',') L ON L.ID = D.REC_ID OR L.ID = ISNULL(D.PARENT_REC_ID, 0)
ORDER BY D.REC_ID
GO