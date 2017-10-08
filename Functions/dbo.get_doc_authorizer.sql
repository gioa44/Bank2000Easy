SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[get_doc_authorizer] (@rec_id int)
RETURNS int
AS
BEGIN
	DECLARE 
		@user_id int,
		@doc_type smallint

	SELECT @doc_type = DOC_TYPE
	FROM dbo.OPS_0000 (NOLOCK)
	WHERE REC_ID = @rec_id
	
	SELECT @user_id = [USER_ID] 
	FROM dbo.DOC_CHANGES DC (NOLOCK)
	WHERE DC.DOC_REC_ID = @rec_id AND (
		(@doc_type IN (102,112) AND DC.DESCRIP LIKE '% -> 2%') OR
		(@doc_type NOT IN (102,112) AND DC.DESCRIP LIKE '% -> 3%')
	)
	ORDER BY REC_ID

	RETURN @user_id
END
GO
