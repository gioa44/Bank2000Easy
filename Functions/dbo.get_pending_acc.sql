SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[get_pending_acc](@rec_id int, @doc_type int, @is_arc bit)
RETURNS TACCOUNT
AS
BEGIN
DECLARE
	@acc TACCOUNT

	IF @is_arc = 0
	BEGIN
		IF @doc_type IN (120, 129)
		BEGIN
			SELECT @acc = CREDIT 
			FROM dbo.DOCS_KASPOR
			WHERE REC_ID = @rec_id
		END
		ELSE
		IF @doc_type IN (100, 109)
		BEGIN
			SELECT @acc = SENDER_ACC 
			FROM dbo.DOCS_PLAT
			WHERE REC_ID = @rec_id
		END
	END
	ELSE
	BEGIN
		IF @doc_type IN (120, 129)
		BEGIN
			SELECT @acc = CREDIT 
			FROM dbo.DOCS_ARC_KASPOR
			WHERE REC_ID = @rec_id
		END
		ELSE
		IF @doc_type IN (100, 109)
		BEGIN
			SELECT @acc = SENDER_ACC 
			FROM dbo.DOCS_ARC_PLAT
			WHERE REC_ID = @rec_id
		END
	END
	RETURN @acc
END
GO
