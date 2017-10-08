SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[get_tariff_for_account_blocking] (@client_id int, @acc_id int, @iso TISO, @amount money, @is_out bit, @fee money OUTPUT)
AS
BEGIN
	SET NOCOUNT ON;
	SET @fee = $0.00;
	RETURN 0;
END
GO
