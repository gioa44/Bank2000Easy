SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- @op_type
--   0 - Add
--   1 - Update
--   2 - Delete
--   3 - Authorize Up
--   4 - Authorize Down

CREATE PROCEDURE [dbo].[doc_check_user_limits]
	@user_id int,
	@iso char(3),
	@amount money, 
	@doc_type smallint,
	@op_type int,
	@rec_state tinyint OUTPUT,
	@lat bit = 0
AS

SET NOCOUNT ON;

DECLARE 
	@d_type smallint,
	@limit_max_value money, 
	@limit_yellow_value money,
	@limit_green_value money

SET @d_type = 
	CASE 
		WHEN @doc_type BETWEEN  10 AND  99 THEN 90
		WHEN @doc_type BETWEEN 100 AND 109 THEN 100 
		WHEN @doc_type BETWEEN 110 AND 119 THEN 110 
		WHEN @doc_type BETWEEN 120 AND 129 THEN 120 
		WHEN @doc_type BETWEEN 130 AND 149 THEN 130 
		WHEN @doc_type BETWEEN 200 AND 249 THEN 200
		ELSE NULL
	END

IF NOT @d_type IS NULL
BEGIN
	SELECT @limit_max_value = LIMIT_MAX_VALUE, @limit_yellow_value = LIMIT_YELLOW_VALUE, @limit_green_value = LIMIT_GREEN_VALUE
	FROM dbo.GROUP_LIMITS (NOLOCK)
	WHERE GROUP_ID = dbo.user_group_id(@user_id) AND DOC_TYPE = @d_type AND OP_TYPE = @op_type AND (ISO = @iso OR ISO = '')
	
	IF @limit_max_value IS NOT NULL AND @amount > @limit_max_value
	BEGIN
		RAISERROR('<ERR>ËÉÌÉÔÉÓ ÂÀÃÀàÀÒÁÄÁÀ</ERR>', 16, 1)
		RETURN 1
	END

	IF @rec_state IS NULL AND @op_type = 0 -- ÃÀÌÀÔÄÁÀ 
	BEGIN
		IF @limit_green_value IS NOT NULL AND @amount <= @limit_green_value
			SET @rec_state = 20
		ELSE
		IF @limit_yellow_value IS NOT NULL AND @amount <= @limit_yellow_value
			SET @rec_state = 10
		ELSE
			SET @rec_state = 0
	END
END
GO
