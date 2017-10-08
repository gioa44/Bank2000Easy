SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- ამ პროცედურამ @bank_code პარამეტრში უნდა დააბრუნოს ფილიალის კოდი (მფო ან სვიფტ კოდი) ანგარიშის მიხედვით
CREATE PROCEDURE [dbo].[GET_BRANCH_FOR_ACCOUNT]
	@bank_code TINTBANKCODE OUTPUT, 
	@account TINTACCOUNT,
	@iso TISO
AS

SET NOCOUNT ON;
GO
