SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--get_clearing_account ფუნქციამ განიცადა ცვლილება. ამ სკრიპტის გაშვებამდე შეინახეთ თქვენი ფუნქცია და შემდეგ გადააკეთეთ @in_bal_acc პარამეტრის შესაბამისად, 
-- @in_bal_acc = 1 დააბრუნოს საბალანსო ანგარიში
-- @in_bal_acc = 0 დააბრუნოს გარესაბალანსო ანგარიში
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

CREATE FUNCTION [dbo].[get_clearing_account](@branch_id int, @ccy char(3), @in_branch bit, @in_bal_acc bit)  
RETURNS TACCOUNT AS  
BEGIN
	DECLARE
		@account TACCOUNT

	--IF @in_bal_acc = 1 --ბალანსური ანგარიშები

	IF @in_branch = 1
		SET @account = 283100 + (CASE WHEN @ccy = 'GEL' THEN 0 ELSE 1000 END)
	ELSE
		SET @account = 483100 + (CASE WHEN @ccy = 'GEL' THEN 0 ELSE 1000 END) --+ @branch_id

	RETURN @account
END
GO
