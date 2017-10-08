SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_GET_RISK_LEVEL]
  @loan_id int,
  @eng_version bit = 0
AS
	SET NOCOUNT ON
	DECLARE
		@reserve_max_category bit,
		@max_category_level tinyint,
		@min_level int

	SELECT @reserve_max_category = RESERVE_MAX_CATEGORY FROM dbo.LOANS WHERE LOAN_ID = @loan_id
	SELECT @max_category_level = ISNULL(MAX_CATEGORY_LEVEL, 0) FROM dbo.LOAN_DETAILS WHERE LOAN_ID = @loan_id
  
	
	SET @min_level = CASE WHEN @reserve_max_category = 1 THEN @max_category_level ELSE 1 END 

	SELECT LEVEL_ID, CODE, CASE WHEN @eng_version = 0 THEN DESCRIP ELSE DESCRIP_LAT END AS DESCRIP
	FROM dbo.LOAN_RISK_LEVELS (NOLOCK) WHERE LEVEL_ID >= ISNULL(@min_level, 1) AND LEVEL_ID < 5
	RETURN 0
GO
