SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ON_USER_BEFORE_ADD_DOC]
	@user_id int OUTPUT,					-- ვინ ამატებს საბუთს
	@owner int OUTPUT,					-- პატრონი (გაჩუმებით = @user_id)
	@doc_type smallint OUTPUT,			-- საბუთის ტიპი
	@doc_date smalldatetime OUTPUT,		-- ტრანზაქციის თარიღი
	@doc_date_in_doc smalldatetime OUTPUT,	-- საბუთის თარიღი OUTPUT, ან სხვა თარიღი
	@debit_id int OUTPUT,					-- დებეტის ანგარიში
	@credit_id int OUTPUT,				-- კრედიტის ანგარიში
	@iso TISO OUTPUT,					-- ვალუტის კოდი
	@amount money OUTPUT,				-- თანხა
	@rec_state tinyint OUTPUT,			-- სტატუსი
	@descrip varchar(150) OUTPUT,		-- დანიშნულება
	@op_code TOPCODE OUTPUT,			-- ოპერაციის კოდი
	@parent_rec_id int OUTPUT,			-- ზემდგომი საბუთის ნომერი
											--  0: არ ყავს ზემდგომი OUTPUT, არ  ყავს შვილი
											-- -1: ყავს შვილი (იშლება ერთად OUTPUT, ავტორიზდება ერთად)
											-- -2: ყავს შვილი (იშლება ერთად OUTPUT, ავტორიზდება ცალ-ცალკე)
											-- -3: ყავს შვილი (იშლება ცალ-ცალკე OUTPUT, ავტორიზდება ცალ-ცალკე)
	@doc_num int OUTPUT,					-- საბუთის ნომერი ან კოდი
	@bnk_cli_id int OUTPUT,				-- ბანკ-კლიენტის მომხმარებლის №
	@account_extra TACCOUNT OUTPUT,		-- დამატებითი ანგარიშის მისათითებელი ველი
	@dept_no int OUTPUT,				-- ფილიალისა და განყოფილების №
	@prod_id int OUTPUT,				-- პროდუქტის ნომერი OUTPUT, რომელიც ამატებს ამ საბუთს
	@foreign_id int OUTPUT,				-- დამტებითი გარე №
	@channel_id int OUTPUT,				-- არხი OUTPUT, რომლითაც ემატება ეს საბუთი
	@is_suspicious bit OUTPUT,			-- არის თუ არა საეჭვო ეს საბუთი

	@relation_id int OUTPUT,
	@flags int OUTPUT,

	-- სალაროს საბუთებისათვის

	@cashier int OUTPUT,
	@chk_serie varchar(4) OUTPUT,
	@treasury_code varchar(9) OUTPUT,
	@tax_code_or_pid varchar(11) OUTPUT,

	-- საგადასახადო დავალებებისათვის

	@sender_bank_code varchar(37) OUTPUT,
	@sender_bank_name varchar(100) OUTPUT,
	@sender_acc TINTACCOUNT OUTPUT,
	@sender_acc_name varchar(100) OUTPUT,
	@sender_tax_code varchar(11) OUTPUT,

	@receiver_bank_code varchar(37) OUTPUT,
	@receiver_bank_name varchar(100) OUTPUT,
	@receiver_acc TINTACCOUNT OUTPUT,
	@receiver_acc_name varchar(100) OUTPUT,
	@receiver_tax_code varchar(11) OUTPUT,

	@extra_info varchar(250) OUTPUT,
	@ref_num varchar(32) OUTPUT,

	-- ლარის საგადასახადო დავალებებისათვის

	@rec_date smalldatetime OUTPUT,	-- საგ. დავალების რეგისტრაციის თარიღი
	@saxazkod varchar(9) OUTPUT,

	-- სავ. საგადასახადო დავალებებისათვის

	@intermed_bank_code varchar(37) OUTPUT,
	@intermed_bank_name varchar(100) OUTPUT,
	@swift_text text OUTPUT,
	@cor_bank_code varchar(37) OUTPUT,
	@cor_bank_name varchar(100) OUTPUT,
	@det_of_charg char(3) OUTPUT,
	@extra_info_descrip bit OUTPUT,  	

	-- სალაროს საბუთებისათვის და სავ. საგადასახადო დავალებებისათვის

	@first_name varchar(50) OUTPUT,
	@last_name varchar(50) OUTPUT, 
	@fathers_name varchar(50) OUTPUT, 
	@birth_date smalldatetime OUTPUT, 
	@birth_place varchar(100) OUTPUT, 
	@address_jur varchar(100) OUTPUT, 
	@address_lat varchar(100) OUTPUT,
	@country varchar(2) OUTPUT, 
	@passport_type_id tinyint OUTPUT, 
	@passport varchar(50) OUTPUT, 
	@personal_id varchar(20) OUTPUT,
	@reg_organ varchar(50) OUTPUT,
	@passport_issue_dt smalldatetime OUTPUT,
	@passport_end_date smalldatetime OUTPUT,

	-- სხვა პარამეტრები

	@check_saldo bit OUTPUT,	-- შეამოწმოს თუ არა მინ. ნაშთი
	@add_tariff bit OUTPUT,		-- დაამატოს თუ არა ტარიფის საბუთი
	@info bit,					-- რეალურად გატარდეს OUTPUT, თუ მხოლოდ ინფორმაციაა
	@lat bit,					-- გამოიტანოს თუ არა შეცდომები ინგლისურად

	@extra_params xml OUTPUT	-- დამატებითი პარამეტრები, რომელიც გადაეცემა ON_USER_AFTER_ADD_DOC პროცედურას
AS

SET NOCOUNT ON;

RETURN 0
GO
