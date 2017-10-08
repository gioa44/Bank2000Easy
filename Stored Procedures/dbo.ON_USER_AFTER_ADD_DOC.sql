SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ON_USER_AFTER_ADD_DOC]
	@rec_id int,					-- რა შიდა ნომრით დაემატა საბუთი
	@user_id int,					-- ვინ ამატებს საბუთს
	@owner int,					-- პატრონი (გაჩუმებით = @user_id)
	@doc_type smallint,			-- საბუთის ტიპი
	@doc_date smalldatetime,		-- ტრანზაქციის თარიღი
	@doc_date_in_doc smalldatetime,	-- საბუთის თარიღი, ან სხვა თარიღი
	@debit_id int,				-- დებეტის ანგარიში
	@credit_id int,				-- კრედიტის ანგარიში
	@iso TISO,					-- ვალუტის კოდი
	@amount money,				-- თანხა
	@rec_state tinyint,			-- სტატუსი
	@descrip varchar(150),		-- დანიშნულება
	@op_code TOPCODE,			-- ოპერაციის კოდი
	@parent_rec_id int,			-- ზემდგომი საბუთის ნომერი
									--  0: არ ყავს ზემდგომი, არ  ყავს შვილი
									-- -1: ყავს შვილი (იშლება ერთად, ავტორიზდება ერთად)
									-- -2: ყავს შვილი (იშლება ერთად, ავტორიზდება ცალ-ცალკე)
									-- -3: ყავს შვილი (იშლება ცალ-ცალკე, ავტორიზდება ცალ-ცალკე)
	@doc_num int,				-- საბუთის ნომერი ან კოდი
	@bnk_cli_id int,			-- ბანკ-კლიენტის მომხმარებლის №
	@account_extra TACCOUNT,	-- დამატებითი ანგარიშის მისათითებელი ველი
	@dept_no int,				-- ფილიალისა და განყოფილების №
	@prod_id int,				-- პროდუქტის ნომერი, რომელიც ამატებს ამ საბუთს
	@foreign_id int,			-- დამტებითი გარე №
	@channel_id int,			-- არხი, რომლითაც ემატება ეს საბუთი
	@is_suspicious bit,			-- არის თუ არა საეჭვო ეს საბუთი

	@relation_id int,
	@flags int,

	-- სალაროს საბუთებისათვის

	@cashier int,
	@chk_serie varchar(4),
	@treasury_code varchar(9),
	@tax_code_or_pid varchar(11),

	-- საგადასახადო დავალებებისათვის

	@sender_bank_code varchar(37),
	@sender_bank_name varchar(100),
	@sender_acc TINTACCOUNT,
	@sender_acc_name varchar(100),
	@sender_tax_code varchar(11),

	@receiver_bank_code varchar(37),
	@receiver_bank_name varchar(100),
	@receiver_acc TINTACCOUNT,
	@receiver_acc_name varchar(100),
	@receiver_tax_code varchar(11),

	@extra_info varchar(250),
	@ref_num varchar(32),

	-- ლარის საგადასახადო დავალებებისათვის

	@rec_date smalldatetime,	-- საგ. დავალების რეგისტრაციის თარიღი
	@saxazkod varchar(9),

	-- სავ. საგადასახადო დავალებებისათვის

	@intermed_bank_code varchar(37),
	@intermed_bank_name varchar(100),
	@swift_text text,
	@cor_bank_code varchar(37),
	@cor_bank_name varchar(100),
	@det_of_charg char(3),
	@extra_info_descrip bit,  	

	-- სალაროს საბუთებისათვის და სავ. საგადასახადო დავალებებისათვის

	@first_name varchar(50),
	@last_name varchar(50), 
	@fathers_name varchar(50), 
	@birth_date smalldatetime, 
	@birth_place varchar(100), 
	@address_jur varchar(100), 
	@address_lat varchar(100),
	@country varchar(2), 
	@passport_type_id tinyint,
	@passport varchar(50), 
	@personal_id varchar(20),
	@reg_organ varchar(50),
	@passport_issue_dt smalldatetime,
	@passport_end_date smalldatetime,

	-- სხვა პარამეტრები

	@check_saldo bit,		-- შეამოწმოს თუ არა მინ. ნაშთი
	@add_tariff bit,		-- დაამატოს თუ არა ტარიფის საბუთი
	@info bit,				-- რეალურად გატარდეს, თუ მხოლოდ ინფორმაციაა
	@lat bit,				-- გამოიტანოს თუ არა შეცდომები ინგლისურად

	@extra_params xml,		-- დამატებითი პარამეტრები, რომელიც დააბრუნა ON_USER_BEFORE_ADD_DOC პროცედურამ
	@info_message varchar(255) OUTPUT -- შეტყობინება, რომელსაც გამოუტანს მომხმარებელს საბუთის დამატების შემდეგ
AS

SET NOCOUNT ON;

RETURN 0
GO
