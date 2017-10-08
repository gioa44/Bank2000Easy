SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[GET_DOC_ARC]
	@rec_id int,
	@doc_type smallint,
	@doc_date smalldatetime = null
AS

SET NOCOUNT ON

IF (@rec_id > 0) AND (@doc_type = -99 OR @doc_date IS NULL)
BEGIN
	IF @doc_date IS NULL 
		SELECT @doc_type = DOC_TYPE, @doc_date = DOC_DATE
		FROM dbo.OPS_ARC (NOLOCK)
		WHERE REC_ID = @rec_id
	ELSE
		SELECT @doc_type = DOC_TYPE 
		FROM dbo.OPS_ARC (NOLOCK)
		WHERE REC_ID = @rec_id AND DOC_DATE = @doc_date
END

IF @doc_type BETWEEN 10 AND 99 /* memo */
BEGIN
	SELECT * FROM dbo.DOCS_ARC_MEMO (NOLOCK)
	WHERE REC_ID = @rec_id AND DOC_DATE = @doc_date
END
ELSE
IF @doc_type BETWEEN 100 AND 109 /* plat */BEGIN
	SELECT * FROM dbo.DOCS_ARC_PLAT (NOLOCK)
	WHERE REC_ID = @rec_id AND DOC_DATE = @doc_date
END
ELSE
IF @doc_type BETWEEN 110 AND 119 /* plat */BEGIN
	SELECT * FROM dbo.DOCS_ARC_VALPLAT (NOLOCK)
	WHERE REC_ID = @rec_id AND DOC_DATE = @doc_date
END
ELSE
IF @doc_type BETWEEN 120 AND 129 /* KasPor */
BEGIN
	SELECT * FROM dbo.DOCS_ARC_KASPOR (NOLOCK)	WHERE REC_ID = @rec_id AND DOC_DATE = @doc_date
END
ELSE
IF @doc_type BETWEEN 130 AND 139 /* KasRor */
BEGIN	SELECT * FROM dbo.DOCS_ARC_KASROR (NOLOCK)
	WHERE REC_ID = @rec_id AND DOC_DATE = @doc_date
END
ELSE
IF @doc_type BETWEEN 140 AND 149 /* KasChe */
BEGIN
	SELECT * FROM dbo.DOCS_ARC_KASCHE (NOLOCK)
	WHERE REC_ID = @rec_id AND DOC_DATE = @doc_date
END
ELSE
IF @doc_type BETWEEN 200 AND 249 /* OutOfBal */
BEGIN	SELECT * FROM dbo.DOCS_ARC_OUT_OF_BAL (NOLOCK)
	WHERE REC_ID = @rec_id AND DOC_DATE = @doc_date
END
ELSEIF @doc_type = 255 /* ALLDocs */
BEGIN	SELECT * FROM dbo.DOCS_ARC (NOLOCK)
	WHERE REC_ID = @rec_id AND DOC_DATE = @doc_date
END
GO
