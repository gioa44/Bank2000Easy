SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_get_contract_docs]
	@depo_id int
AS
SET NOCOUNT ON;

DECLARE
	@doc_rec_id int

SELECT @doc_rec_id = DOC_REC_ID
FROM dbo.DEPO_OP (NOLOCK)
WHERE DEPO_ID = @depo_id AND OP_TYPE = dbo.depo_fn_const_op_active()

SELECT REC_ID, DOC_DATE, ISO, DOC_TYPE
FROM dbo.OPS_0000 (NOLOCK)
WHERE REC_ID = @doc_rec_id


RETURN 0

GO
