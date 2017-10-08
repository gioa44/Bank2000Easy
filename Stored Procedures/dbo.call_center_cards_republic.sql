SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[call_center_cards_republic]
	@client_no int
AS
	-- TODO: Write your code here

	SELECT
		convert(int, 12) AS _CARD_ID,
		convert(varchar(16), '1111222233334444') AS CARD_NUM,
		convert(decimal(15,0), 123123123) AS CARD_ACCOUNT,
		convert(char(3), 'USD') AS CARD_ISO,
		convert(smalldatetime, '20070101') AS _VALID_DATE
GO
