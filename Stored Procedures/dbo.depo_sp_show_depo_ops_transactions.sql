SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--dokho

CREATE PROCEDURE [dbo].[depo_sp_show_depo_ops_transactions]
  @op_id int
AS
SET NOCOUNT ON;

DECLARE 
	@op_date smalldatetime,
	@docs_rec_id int,
	@accrue_docs_rec_id int,
	@depo_id int

SELECT @depo_id = DEPO_ID, @op_date = OP_DATE, @docs_rec_id = DOC_REC_ID, @accrue_docs_rec_id = ACCRUE_DOC_REC_ID
FROM dbo.DEPO_OP 
WHERE OP_ID = @op_id

IF @op_date < dbo.bank_open_date()
BEGIN
	DECLARE
		@op_date_min smalldatetime,
		@op_date_max smalldatetime
	
	SET @op_date_min = convert(smalldatetime, convert(char(4), YEAR(@op_date)) + '0101')
	SET @op_date_max = convert(smalldatetime, convert(char(4), YEAR(@op_date)) + '1231')

	SELECT DA.* 
	FROM dbo.DOCS_ARC_ALL DA (NOLOCK)
	WHERE (DA.DOC_DATE BETWEEN @op_date_min and @op_date_max) AND (DA.REC_ID = @accrue_docs_rec_id OR DA.PARENT_REC_ID = @accrue_docs_rec_id)
	UNION
	SELECT DA.* 
	FROM dbo.DOCS_ARC_ALL DA (NOLOCK)
	WHERE (DA.DOC_DATE BETWEEN @op_date_min and @op_date_max) AND (DA.REC_ID = @docs_rec_id OR DA.PARENT_REC_ID = @accrue_docs_rec_id)
	OPTION (RECOMPILE)
END
ELSE
BEGIN
	SELECT DA.* 
	FROM dbo.DOCS_ALL DA (NOLOCK)
	WHERE DA.OP_NUM = @accrue_docs_rec_id
	UNION
	SELECT DA.* 
	FROM dbo.DOCS_ALL DA (NOLOCK)
	WHERE DA.REC_ID = @docs_rec_id OR DA.PARENT_REC_ID = @docs_rec_id
	OPTION (RECOMPILE)
END
GO
