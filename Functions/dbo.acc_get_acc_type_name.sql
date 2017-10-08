SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[acc_get_acc_type_name] (@acc_id int, @lat bit = 0)
RETURNS varchar(50)
AS
BEGIN
	DECLARE @name varchar(50)

	SELECT @name = dbo.get_acc_type_name (A.ACC_TYPE, A.ACC_SUBTYPE, @lat)
	FROM dbo.ACCOUNTS A (NOLOCK)
	WHERE A.ACC_ID = @acc_id

	RETURN @name
END
GO
