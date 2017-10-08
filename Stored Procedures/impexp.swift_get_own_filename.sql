SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[swift_get_own_filename]
	@msg_type varchar(10),
	@doc_rec_id int,
	@doc_date smalldatetime
AS
BEGIN
	DECLARE
		@msg_count int,
		@file_name varchar(128)

	SET @file_name = ''

	DECLARE
		@y int,
		@m int,
		@d int

	SET @y = DATEPART(yy, @doc_date)
	SET @m = DATEPART(mm, @doc_date)
	SET @d = DATEPART(dd, @doc_date)

	SELECT @msg_count = MSG_COUNT
	FROM impexp.SWIFT_MSG_COUNT (NOLOCK)
	WHERE DOC_DATE = @doc_date AND MSG_TYPE = @msg_type

	IF @msg_count IS NULL
		SET @msg_count = 1
	ELSE
		SET @msg_count = @msg_count + 1

	DELETE FROM impexp.SWIFT_MSG_COUNT
	WHERE DOC_DATE = @doc_date AND MSG_TYPE = @msg_type

	INSERT INTO impexp.SWIFT_MSG_COUNT(DOC_DATE, MSG_TYPE, MSG_COUNT)
	VALUES(@doc_date, @msg_type, @msg_count)


	IF @msg_type = 'MT103'
	BEGIN
		SET @file_name = 'SGBR-ALTA.D' +
			REPLICATE('0', 2 - LEN(convert(varchar(2), @d))) + convert(varchar(2), @d) +
			REPLICATE('0', 2 - LEN(convert(varchar(2), @m))) + convert(varchar(2), @m) +
			SUBSTRING(convert(varchar(4), @y), 3, 2) + '_' + 
			REPLICATE('0', 8 - LEN(convert(varchar(8), @msg_count))) + convert(varchar(8), @msg_count)
	END

	IF @msg_type = 'MT940' OR @msg_type = 'MT950'
	BEGIN
		SET @file_name = 'SGBR-ALTA940950.D' +
			REPLICATE('0', 2 - LEN(convert(varchar(2), @d))) + convert(varchar(2), @d) +
			REPLICATE('0', 2 - LEN(convert(varchar(2), @m))) + convert(varchar(2), @m) +
			SUBSTRING(convert(varchar(4), @y), 3, 2) + '_' + 
			REPLICATE('0', 8 - LEN(convert(varchar(8), @msg_count))) + convert(varchar(8), @msg_count)
	END

	SELECT @file_name AS [FILE_NAME]
	RETURN
END
GO
