SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[so_get_acc_balance]
	@date datetime,					-- თარიღი რომელი რისთვისაც ხდება ნაშთის გაგება
	@client_no int,					-- კლიენტის ნომერი
	@acc_id int,					-- ანგარიშის ACC_ID
	@acc_type int,					-- ანგარიშის ტიპი (ცხრილიდან ACC_TYPES)
	@acc_sub_type int,				-- ანგარიშის ქვეტიპი (ცხრილიდან ACC_SUBTYPES)
	@acc_no TACCOUNT,				-- ანგარიშის ნომერი
	@is_debit bit,					-- სადებეტო ანგარიშზე ხდება გაგება ნაშთის, თუ საკრედიტო ანგარიშზე
	@ccy TISO,						-- თანხის ვალუტა
	@ref_no bigint,					-- ტრანზაქციის უნიკალური ნომერი, მხოლოდ ნაშთის გაგებისას შეიძლება იყოს NULL
	@block_amount money,			-- რა თანხა უნდა დაიბლოკოს (მაგ. საპროცესინგოში) ამ შემთხვევაში @amount-ის შევსება არ არის აუცილებელი, NULL (და ასევე 0) მიუთითებს რომ თანხის დაბლოკვა არ უნდა განხორციელდეს და @amount პარამეტრი აუცილებელად უნდა შეივსოს
	@cancel_operation bit,			-- უარყოს ტრანზაქცია (მაგ. დაბლოკილი თანხა საპროცესინგოში)
	@amount money OUTPUT,			-- შემავალი პარამეტრად: თანხა რაც ბანკის ბაზაში არის გამოყენებადი; გამოსავალ პარამეტრად: მაგ. თანხა რაც საპროცესინგოშია
	@check_saldo bit OUTPUT,		-- გაითვალისწინოს ნაშთის კონტროლი
	@error_code int = 0 OUTPUT,		-- შესრულებისას შეცდომის კოდი
	@error_msg varchar(250) = NULL OUTPUT,		-- შესრულებისას შეცდომის შეტყობინება
	@error_msg_lat varchar(250) = NULL OUTPUT	-- შესრულებისას შეცდომის შეტყობინება ლათ
AS
		
	RETURN 0
GO
