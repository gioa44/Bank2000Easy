SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_fn_get_report_data_value_op](@depo_id int, @param_name varchar(max), @is_lat bit, @op_id int)
RETURNS varchar(1500)
AS
BEGIN
	DECLARE
		@result varchar(1500)

	DECLARE
		@op_type smallint

	SET @result = 'N/A'

	SELECT @op_type = OP_TYPE
	FROM dbo.DEPO_OP (NOLOCK)
	WHERE OP_ID = @op_id
		
	IF @param_name = 'OP_COUNT'
	BEGIN
		DECLARE
			@op_count int

		SELECT @op_count = COUNT(*)
		FROM dbo.DEPO_OP (NOLOCK)
		WHERE DEPO_ID = @depo_id AND OP_ID <= @op_id AND OP_TYPE = @op_type

		SET @result = convert(varchar(20), @op_count)
	END

	RETURN @result
END
GO
