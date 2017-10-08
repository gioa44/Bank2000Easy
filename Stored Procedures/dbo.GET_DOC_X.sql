SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[GET_DOC_X]
	@rec_id int,
	@doc_type smallint,
	@doc_date smalldatetime = null
AS

SET NOCOUNT ON

DECLARE @is_in_arc bit

SET @is_in_arc = 0

IF (@rec_id > 0) AND (@doc_type = -99 OR @doc_date IS NULL)
BEGIN
	IF @doc_date IS NULL 
		SELECT @doc_type = DOC_TYPE, @doc_date = DOC_DATE
		FROM dbo.OPS_0000 (NOLOCK)
		WHERE REC_ID = @rec_id
	ELSE
		SELECT @doc_type = DOC_TYPE 
		FROM dbo.OPS_0000 (NOLOCK)
		WHERE REC_ID = @rec_id AND DOC_DATE = @doc_date

	IF @@ROWCOUNT = 0
	BEGIN
		IF @doc_date IS NULL 
			SELECT @doc_type = DOC_TYPE, @doc_date = DOC_DATE
			FROM dbo.OPS_ARC (NOLOCK)
			WHERE REC_ID = @rec_id
		ELSE
			SELECT @doc_type = DOC_TYPE 
			FROM dbo.OPS_ARC (NOLOCK)
			WHERE REC_ID = @rec_id AND DOC_DATE = @doc_date
		
		IF @@ROWCOUNT = 0
		BEGIN
			RAISERROR ('ÓÀÁÖÈÉ ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1)
			RETURN 1
		END
		ELSE
			SET @is_in_arc = 1
	END
END
ELSE
	SET @is_in_arc = CASE WHEN @doc_date < dbo.bank_open_date() THEN 1 ELSE 0 END

IF @is_in_arc = 1
	EXEC dbo.GET_DOC_ARC @rec_id = @rec_id,	@doc_type = @doc_type, @doc_date = @doc_date
ELSE
	EXEC dbo.GET_DOC @rec_id = @rec_id,	@doc_type = @doc_type, @doc_date = @doc_date
GO
