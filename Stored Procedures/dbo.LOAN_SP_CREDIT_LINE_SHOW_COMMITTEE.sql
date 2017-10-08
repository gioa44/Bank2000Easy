SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_CREDIT_LINE_SHOW_COMMITTEE]
	@user_id int,
	@authorize bit
AS
SELECT *
FROM
  dbo.LOAN_VW_CREDIT_LINES
WHERE (@authorize = 1) AND (STATE IN (0, 20))
GO