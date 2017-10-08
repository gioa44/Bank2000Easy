SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[GET_DOC]
	@rec_id	int,
	@doc_type smallint,
	@doc_date smalldatetime = null
AS

SET NOCOUNT ON

IF (@rec_id > 0) AND (@doc_type = -99)
	SELECT @doc_type = DOC_TYPE 
	FROM dbo.OPS_0000 (ROWLOCK) 
	WHERE REC_ID = @rec_id

IF @doc_type BETWEEN 10 AND 99 /* memo */
BEGIN	SELECT * FROM dbo.DOCS_MEMO (ROWLOCK)
	WHERE REC_ID = @rec_id
END
ELSE
IF @doc_type BETWEEN 100 AND 109 /* plat */
BEGIN
	SELECT * FROM dbo.DOCS_PLAT (ROWLOCK)
	WHERE REC_ID = @rec_id
END
ELSE
IF @doc_type BETWEEN 110 AND 119 /* plat */
BEGIN
	SELECT * FROM dbo.DOCS_VALPLAT (ROWLOCK)
	WHERE REC_ID = @rec_id
END
ELSE
IF @doc_type BETWEEN 120 AND 129 /* KasPor */
BEGIN
	SELECT * FROM dbo.DOCS_KASPOR (ROWLOCK)	WHERE REC_ID = @rec_id
END
ELSE
IF @doc_type BETWEEN 130 AND 139 /* KasRor */BEGIN	SELECT * FROM dbo.DOCS_KASROR (ROWLOCK)
	WHERE REC_ID = @rec_id
END
ELSE
IF @doc_type BETWEEN 140 AND 149 /* KasChe */
BEGIN
	SELECT * FROM dbo.DOCS_KASCHE (ROWLOCK)
	WHERE REC_ID = @rec_id
END
ELSE
IF @doc_type BETWEEN 200 AND 249 /* OutOfBal */
BEGIN	SELECT * FROM dbo.DOCS_OUT_OF_BAL (ROWLOCK)
	WHERE REC_ID = @rec_id
END
ELSE
IF @doc_type = 255 /* ALLDocs */
BEGIN	SELECT * FROM dbo.DOCS_ALL (ROWLOCK)
	WHERE REC_ID = @rec_id
END
GO
