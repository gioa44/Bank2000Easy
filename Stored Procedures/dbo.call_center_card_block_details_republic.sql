SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[call_center_card_block_details_republic]
	@client_no int,
	@card_id int,
	@card_num varchar(16),
	@card_account TACCOUNT,
	@card_iso TISO,
	@user_id int
AS
	DECLARE @T TABLE(
		REC_ID int NOT NULL IDENTITY(1, 1) PRIMARY KEY,
		DESCRIP varchar(150) NOT NULL,
		[VALUE] varchar(150) NOT NULL,
		ROW_COLOR int NOT NULL DEFAULT(0xFFFFFF)
	)
	
	INSERT INTO @T(DESCRIP, [VALUE], ROW_COLOR)
	VALUES('BLOCK_DESCRIP', 'BLOCK_VALUE', 0xFFFFFF)

	SELECT * FROM @T
GO
