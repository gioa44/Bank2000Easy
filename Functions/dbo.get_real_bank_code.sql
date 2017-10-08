SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- დააბრუნოს ვირტუალური ფილაილის რეალური კოდი
CREATE FUNCTION [dbo].[get_real_bank_code] (@bank_code TINTBANKCODE)
RETURNS TINTBANKCODE
AS
BEGIN
	DECLARE @real_code TINTBANKCODE
	SET @real_code = @bank_code
	
--	IF @bank_code = '220201068' OR @bank_code = '220301068'
--		SET @real_code = '220101068'
	RETURN @real_code
END
GO
