SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tcd_sp_tcd_get_ops]
(	
	@tcd_serial_id varchar(50),
	@start_date smalldatetime = NULL,
	@end_date smalldatetime = NULL,
	@is_err bit = 0
)
AS
BEGIN

	SET @start_date = convert(smalldatetime,floor(convert(real, @start_date)))
	SET @end_date = convert(smalldatetime,floor(convert(real, @end_date)))


	IF @is_err = 0
	BEGIN
		SELECT	TC.DESCRIP AS COMMAND, TR.DESCRIP REPLY_MSG, U.[USER_NAME], 
				T.OP_DATE
		FROM dbo.TCD_OPS T
			INNER JOIN dbo.TCD_COMMAND_TYPES TC (NOLOCK) ON T.COMMAND_ID = TC.COMMAND_ID
			INNER JOIN dbo.TCD_REPLY_MSG TR (NOLOCK) ON T.REPLY_MSG_ID = TR.MSG_ID
			INNER JOIN dbo.USERS U (NOLOCK) ON T.[USER_ID] = U.[USER_ID]
		WHERE T.TCD_SERIAL_ID = @tcd_serial_id AND
		(@start_date IS NULL OR convert(smalldatetime,floor(convert(real, T.OP_DATE)))>=@start_date)AND(@end_date IS NULL OR convert(smalldatetime,floor(convert(real, T.OP_DATE)))<=@end_date)
	END
	ELSE
	BEGIN
		SELECT	TC.DESCRIP AS COMMAND, TR.DESCRIP REPLY_MSG, U.[USER_NAME], 
				T.OP_DATE
		FROM dbo.TCD_OPS T
			INNER JOIN dbo.TCD_COMMAND_TYPES TC (NOLOCK) ON T.COMMAND_ID = TC.COMMAND_ID
			INNER JOIN dbo.TCD_REPLY_MSG TR (NOLOCK) ON T.REPLY_MSG_ID = TR.MSG_ID AND TR.CODE NOT IN ('SuccessFullCommand', 'LowLevel', 'RejectedNotes', 'RCAlmostFull')
			INNER JOIN dbo.USERS U (NOLOCK) ON T.[USER_ID] = U.[USER_ID]
		WHERE T.TCD_SERIAL_ID = @tcd_serial_id AND
		(@start_date IS NULL OR convert(smalldatetime,floor(convert(real, T.OP_DATE)))>=@start_date)AND(@end_date IS NULL OR convert(smalldatetime,floor(convert(real, T.OP_DATE)))<=@end_date)
	END
	RETURN 0
END
GO
