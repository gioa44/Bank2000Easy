SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[sys_group_has_right](@group_id int, @task_id int, @right_id tinyint) 
RETURNS bit
AS
BEGIN
	DECLARE
		@bit_mask int,
		@has_right bit

	SET @has_right = 0
	SET @bit_mask = CASE @right_id WHEN 1 THEN 1 WHEN 2 THEN 2 WHEN 3 THEN 4 WHEN 4 THEN 8 WHEN 5 THEN 16 WHEN 6 THEN 32 WHEN 7 THEN 64 WHEN 8 THEN 128 END

	IF CONVERT(tinyint, (SELECT SUBSTRING(G.ACCESS_STRING, @task_id - 1, 2) FROM dbo.GROUPS G (NOLOCK) WHERE GROUP_ID = @group_id)) &  @bit_mask <> 0
		SET @has_right = 1

	RETURN @has_right
END
GO
