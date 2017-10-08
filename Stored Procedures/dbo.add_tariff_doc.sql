SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[add_tariff_doc]
	@doc_rec_id int, 
	@tar_kind smallint,				-- 0 - ჩვეულებრივი საბუთი, 1 - კონვერტაცია. ტარიფის აღება 1–ი საბუთიდან , 2 – კონვერტაცია. ტარიფის აღება 2–ე საბუთიდან 

	@fee_rec_id int = NULL OUTPUT,	-- აბრუნებს დამატებული საბუთის REC_ID–ს
	@fee_amount money = NULL OUTPUT, -- აბრუნებს დამატებული საბუთის თანხას (ტარიფის თანხას)

	@user_id int,					-- ვინ ამატებს საბუთს
	@owner int = NULL,				-- პატრონი (გაჩუმებით = @user_id)
	@dept_no int = null,			-- ფილიალისა და განყოფილების №

	@rec_state tinyint = 0,			-- სტატუსი

	@doc_type smallint,				-- საბუთის ტიპი
	@doc_date smalldatetime,		-- ტრანზაქციის თარიღი

	@debit_id int,					-- დებეტის ანგარიში
	@credit_id int,					-- კრედიტის ანგარიში
	@iso TISO = 'GEL',				-- ვალუტის კოდი
	@amount money,					-- თანხა
	@amount2 money = null,			-- კონვერტაციის თანხა 2
	@cash_amount money,				-- სალაროს დასაბეგრი თანხა
	@op_code TOPCODE = '',			-- ოპერაციის კოდი
	@doc_num int = NULL,			-- საბუთის ნომერი ან კოდი

	@account_extra TACCOUNT = NULL,	-- დამატებითი ანგარიშის მისათითებელი ველი
	@prod_id int = null,			-- პროდუქტის ნომერი, რომელიც ამატებს ამ საბუთს
	@foreign_id int = null,			-- დამატებითი გარე №
	@channel_id int = 0,			-- არხი, რომლითაც ემატება ეს საბუთი
	@relation_id int = null,

	-- სალაროს საბუთებისათვის

	@cashier int = NULL,

	-- საგადასახადო დავალებებისათვის

	@receiver_bank_code varchar(37) = NULL,

	-- სავ. საგადასახადო დავალებებისათვის

	@det_of_charg char(3) = NULL,

	-- კონვერტაციებისათვის

	@rate_flags int,

	-- სხვა პარამეტრები

	@info bit = 0,			-- რეალურად გატარდეს, თუ მხოლოდ ინფორმაციაა
	@lat bit = 0			-- გამოიტანოს თუ არა შეცდომები ინგლისურად
AS

SET @fee_rec_id = NULL
SET @fee_amount = NULL

DECLARE	
	@credit_id0 int
SET @credit_id0 = @credit_id

DECLARE 
	@tariff_id int,
	@client_no int,
	@tariff_doc_type smallint,
	@tariff_op_code varchar(5),
	@descrip varchar(150),
	@flags int,
	@r int

SELECT @tariff_id = A.TARIFF, @client_no = CLIENT_NO
FROM dbo.ACCOUNTS A (NOLOCK)
WHERE A.ACC_ID = @debit_id

IF @tar_kind = 0
BEGIN
	SET @tariff_op_code = '*TF%*'
	SET @tariff_doc_type = 12
END
ELSE
BEGIN
	SET @tariff_op_code = '*CV%*'
	SET @tariff_doc_type = 18
END

EXEC @r = dbo.get_tariff_amount
	@result = @fee_amount OUTPUT,		-- აბრუნებს ტარიფის თანხას
	@tariff_id = @tariff_id,
	@tariff_doc_type = @tariff_doc_type OUTPUT,
	@tariff_op_code = @tariff_op_code OUTPUT,
	@client_no = @client_no,
	@descrip = @descrip OUTPUT,
	@user_id = @user_id,
	@owner = @owner,
	@dept_no = @dept_no,
	@doc_type = @doc_type,
	@doc_date = @doc_date,
	@debit_id = @debit_id OUTPUT,
	@credit_id = @credit_id OUTPUT,
	@iso = @iso OUTPUT,
	@amount = @amount,
	@amount2 = @amount2,
	@cash_amount = @cash_amount,
	@flags = @flags OUTPUT,
	@op_code = @op_code,
	@doc_num = @doc_num,
	@account_extra = @account_extra,
	@prod_id = @prod_id OUTPUT,
	@foreign_id = @foreign_id OUTPUT,
	@channel_id = @channel_id,
	@cashier = @cashier,
	@receiver_bank_code = @receiver_bank_code,
	@det_of_charg = @det_of_charg,
	@rate_flags = @rate_flags,
	@info = @info
IF @@ERROR <> 0 OR @r <> 0 RETURN 2

SET @fee_amount = ROUND(@fee_amount, 2)

IF ISNULL(@fee_amount, $0) <= 0 RETURN (0)

EXEC @r = dbo._INTERNAL_ADD_DOC
	@rec_id = @fee_rec_id OUTPUT,			
	@owner = @owner,
	@doc_type = @tariff_doc_type,
	@doc_date = @doc_date,
	@debit_id = @debit_id,
	@credit_id = @credit_id,
	@iso = @iso,
	@amount = @fee_amount,
	@rec_state = @rec_state,
	@descrip = @descrip,
	@op_code = @tariff_op_code,
	@parent_rec_id = @doc_rec_id,
	@doc_num = @doc_num,
	@dept_no = @dept_no,
	@prod_id = @prod_id,
	@foreign_id = @foreign_id,
	@channel_id = @channel_id,
	@relation_id = @relation_id,
	@flags = @flags
IF @@ERROR <> 0 OR @r <> 0 RETURN 5

EXEC @r = dbo.ON_USER_AFTER_ADD_TARIFF_DOC
	@tariff_doc_rec_id = @fee_rec_id,
	@tariff_amount = @fee_amount,
	@tariff_id = @tariff_id,
	@tariff_doc_type = @tariff_doc_type,
	@tariff_op_code = @tariff_op_code,
	@client_no = @client_no,
	@descrip = @descrip,
	@user_id = @user_id,
	@owner = @owner,
	@dept_no = @dept_no,
	@doc_type = @doc_type,
	@doc_date = @doc_date,
	@debit_id = @debit_id,
	@credit_id = @credit_id,
	@iso = @iso,
	@amount = @amount,
	@amount2 = @amount2,
	@cash_amount = @cash_amount,
	@flags = @flags,
	@op_code = @op_code,
	@doc_num = @doc_num,
	@extra = @account_extra,
	@prod_id = @prod_id,
	@foreign_id = @foreign_id,
	@channel_id = @channel_id,
	@cashier = @cashier,
	@receiver_bank_code = @receiver_bank_code,
	@det_of_charg = @det_of_charg,
	@rate_flags = @rate_flags,
	@info = @info
IF @@ERROR <> 0 OR @r <> 0 RETURN 6

RETURN (0)
GO
