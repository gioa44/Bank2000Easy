SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_get_op_docs]
	@doc_rec_id int = NULL,
	@accrue_doc_rec_id int = NULL
AS
SET NOCOUNT ON;
	SELECT D.OP_NUM, D.OP_CODE, D.DEBIT, D.CREDIT, D.ISO, D.AMOUNT, D.DESCRIP 
	FROM dbo.DOCS_ALL D (NOLOCK)
	WHERE (D.OP_NUM = @accrue_doc_rec_id)
	UNION
	SELECT D.OP_NUM, D.OP_CODE, D.DEBIT, D.CREDIT, D.ISO, D.AMOUNT, D.DESCRIP 
	FROM dbo.DOCS_ALL D (NOLOCK)
	WHERE (D.OP_NUM = @doc_rec_id)

RETURN 0

GO
