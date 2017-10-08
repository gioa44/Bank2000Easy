SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_SHOW_COMMITTEE_NOTES]
	@user_id int,
	@eng_version bit
AS
SELECT V.LOAN_ID, V.REC_ID, V.DATE_TIME, V.OWNER, V.USER_NAME, V.OP_TYPE, CASE WHEN @eng_version = 1 THEN V.OP_DESCRIP_LAT ELSE V.OP_DESCRIP END AS OP_DESCRIP, V.NOTE
FROM dbo.LOANS L
	INNER JOIN dbo.LOAN_VW_LOAN_NOTES V ON V.LOAN_ID = L.LOAN_ID
WHERE
	(L.STATE IN (0, 10) AND L.AUTHORIZE_LEVEL IN (10, 20)) OR
	(L.STATE IN (10, 20) AND (L.AUTHORIZE_LEVEL = 20))
GO
