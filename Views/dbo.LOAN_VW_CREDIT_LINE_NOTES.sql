SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[LOAN_VW_CREDIT_LINE_NOTES]
AS
SELECT N.CREDIT_LINE_ID, N.REC_ID, N.DATE_TIME, N.OWNER, N.OP_TYPE, T.DESCRIP AS OP_DESCRIP, T.DESCRIP_LAT AS OP_DESCRIP_LAT, N.NOTE
FROM dbo.LOAN_CREDIT_LINES L
	INNER JOIN dbo.LOAN_CREDIT_LINE_NOTES N ON N.CREDIT_LINE_ID = L.CREDIT_LINE_ID
	LEFT OUTER JOIN dbo.LOAN_CREDIT_LINE_OP_TYPES T ON N.OP_TYPE = T.TYPE_ID

GO