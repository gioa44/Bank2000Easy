SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[sys_fix_group_rights]
AS

DECLARE 
	@task_id int,
	@group_id int,
	@right_id int,
	@bit_mask tinyint,
	@access_string binary(255),
	@r int

DECLARE cc CURSOR 
FOR 
SELECT GROUP_ID
FROM dbo.GROUPS

OPEN cc

FETCH NEXT FROM cc INTO @group_id
WHILE @@FETCH_STATUS = 0
BEGIN
	SET @task_id = 1

	SELECT @access_string = ACCESS_STRING
	FROM dbo.GROUPS
	WHERE GROUP_ID = @group_id

	WHILE @task_id < 255
	BEGIN
		SELECT @r = SUBSTRING(@access_string, @task_id, 1)
		
		SET @right_id = 1
		WHILE @right_id <= 8
		BEGIN
			SET @bit_mask = CASE @right_id WHEN 1 THEN 1 WHEN 2 THEN 2 WHEN 3 THEN 4 WHEN 4 THEN 8 WHEN 5 THEN 16 WHEN 6 THEN 32 WHEN 7 THEN 64 WHEN 8 THEN 128 END

			IF NOT EXISTS(SELECT * FROM dbo.TASK_RIGHTS WHERE TASK_ID = @task_id AND TASK_RIGHT_ID = @right_id)
				SET @r = @r & (~ @bit_mask)

			SET @right_id = @right_id + 1
		END

		SET @access_string = SUBSTRING(@access_string, 1, @task_id - 1) + CONVERT(binary(1), @r) + SUBSTRING(@access_string, @task_id + 1, 1000)

		SET @task_id = @task_id + 1
	END

	UPDATE dbo.GROUPS
	SET ACCESS_STRING = @access_string
	WHERE GROUP_ID = @group_id

	FETCH NEXT FROM cc INTO @group_id
END

CLOSE cc
DEALLOCATE cc
GO
