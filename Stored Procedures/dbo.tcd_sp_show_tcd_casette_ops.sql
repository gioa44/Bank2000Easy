SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tcd_sp_show_tcd_casette_ops]
(
	@op_id int
)
AS
BEGIN

	DECLARE 
		@op_date smalldatetime,
		@docs_rec_id int

	SELECT @op_date = OP_DATE, @docs_rec_id = DOC_REC_ID
	FROM dbo.TCD_CASETTE_OPS
	WHERE OP_ID = @op_id

	IF @op_date < dbo.bank_open_date()
		SELECT DA.* 
		FROM dbo.DOCS_ARC_ALL DA (NOLOCK)
		WHERE DA.REC_ID = @docs_rec_id OR DA.PARENT_REC_ID = @docs_rec_id
	ELSE
		SELECT DA.* 
		FROM dbo.DOCS_ALL DA (NOLOCK)
		WHERE DA.REC_ID = @docs_rec_id OR DA.PARENT_REC_ID = @docs_rec_id
	
END
GO
