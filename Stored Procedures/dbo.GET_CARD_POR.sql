SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[GET_CARD_POR]
	@por int OUTPUT,
	@bank_code int OUTPUT,
	@date smalldatetime
AS

EXEC GET_SETTING_INT 'PC_BANK_CODE', @bank_code OUTPUT

IF EXISTS(SELECT * FROM INI_DT WHERE IDS = 'CARD_EXP_FILE_DATE' AND VALS = @date)
BEGIN

	EXEC GET_SETTING_INT 'PC_FILE_POR', @por OUTPUT
	
	UPDATE INI_INT
	SET VALS = VALS + 1
	WHERE IDS = 'PC_FILE_POR'

END
ELSE
BEGIN

	SET @por = 0

	UPDATE INI_INT
	SET VALS = @por + 1
	WHERE IDS = 'PC_FILE_POR'

	UPDATE INI_DT
	SET VALS = @date
	WHERE IDS = 'CARD_EXP_FILE_DATE'

END

RETURN (0)
GO
