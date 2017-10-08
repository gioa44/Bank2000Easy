SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[GET_CASHIER_ACC]
	@dept_id int,
	@user_id int,
	@param_name varchar(50),
	@time_type int = NULL,
	@acc TACCOUNT OUTPUT
AS

SET NOCOUNT ON

DECLARE
	@sql nvarchar(200),
	@param varchar(60),
	@work_time smalldatetime,
	@cur_time smalldatetime

SELECT @work_time = VALS FROM INI_DT
WHERE IDS = 'WORK_KAS_TIME'

SET @work_time = @work_time - convert(smalldatetime,floor(convert(real,@work_time)))
SET @cur_time = GETDATE() - convert(smalldatetime,floor(convert(real,GETDATE())))

IF @time_type IS NULL
BEGIN
	IF @cur_time >= @work_time
		SET @param = 'NIGHT_' + @param_name
	ELSE
		SET @param = @param_name
END
ELSE
BEGIN
	IF @time_type = 1
		SET @param = @param_name
	ELSE
		SET @param = 'NIGHT_' + @param_name
END

SET @sql = N'SELECT @acc = ' + @param  + ' FROM dbo.USERS (NOLOCK) WHERE USER_ID = @user_id AND (IS_OPERATOR_CASHIER = 1 OR IS_CASHIER = 1)'
EXEC sp_executesql @sql, N'@acc TACCOUNT output, @user_id int', @acc OUTPUT, @user_id
IF @@ERROR <> 0
	SET @acc = 0

IF ISNULL(@acc, 0) = 0
	EXEC dbo.GET_DEPT_ACC @dept_id=@dept_id, @param_name=@param_name, @acc=@acc OUTPUT 

RETURN (0)
GO
