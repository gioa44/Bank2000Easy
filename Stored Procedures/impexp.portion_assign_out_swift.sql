SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- OBSOLETE
CREATE PROCEDURE [impexp].[portion_assign_out_swift] 
	@doc_id int, 
	@date smalldatetime,
	@por int,
	@user_id int
AS

SET NOCOUNT ON;

UPDATE impexp.DOCS_OUT_SWIFT
SET PORTION_DATE = @date, PORTION = @por
WHERE DOC_REC_ID = @doc_id

GO
