SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- ეს პროცედურა არის მხოლოდ თავსებადობისათვის
-- გამოიყენეთ dbo.ADD_DOC4

CREATE  PROCEDURE [dbo].[ADD_DOC]
  @rec_id int OUTPUT,			-- რა შიდა ნომრით დაემატა საბუთი
  @user_id int,					-- ვინ ამატებს საბუთს
  @owner int = NULL,			-- პატრონი (გაჩუმებით = @user_id)
  @doc_type smallint,			-- საბუთის ტიპი
  @doc_date smalldatetime,		-- ტრანზაქციის თარიღი
  @doc_date_in_doc smalldatetime = NULL,	-- საბუთის თარიღი, ან სხვა თარიღი
  @debit_branch_id int = null,				-- დებეტის ფილიალი
  @debit TACCOUNT,				-- დებეტის ანგარიში
  @credit_branch_id int = null,				-- კრედიტის ფილიალი
  @credit TACCOUNT,				-- კრედიტის ანგარიში
  @iso TISO = 'GEL',			-- ვალუტის კოდი
  @amount money,				-- თანხა
  @rec_state tinyint = 0,		-- სტატუსი
  @descrip varchar(150) = NULL,	-- დანიშნულება
  @op_code TOPCODE = '',		-- ოპერაციის კოდი
  @parent_rec_id int = 0,		-- ზემდგომი საბუთის ნომერი
								--  0: არ ყავს ზემდგომი, არ  ყავს შვილი
								-- -1: ყავს შვილი (იშლება ერთად, ავტორიზდება ერთად)
								-- -2: ყავს შვილი (იშლება ერთად, ავტორიზდება ცალ-ცალკე)
								-- -3: ყავს შვილი (იშლება ცალ-ცალკე, ავტორიზდება ცალ-ცალკე)
  @doc_num int = NULL,			-- საბუთის ნომერი ან კოდი
  @bnk_cli_id int = NULL,		-- ბანკ-კლიენტის მომხმარებლის №
  @account_extra TACCOUNT = NULL,	-- დამატებითი ანგარიშის მისათითებელი ველი
  @dept_no int = null,				-- ფილიალისა და განყოფილების №
  @prod_id int = null,				-- პროდუქტის ნომერი, რომელიც ამატებს ამ საბუთს
  @foreign_id int = null,			-- დამტებითი გარე №
  @channel_id int = 0,				-- არხი, რომლითაც ემატება ეს საბუთი
  @is_suspicious bit = 0,			-- არის თუ არა საეჭვო ეს საბუთი

  @relation_id int = NULL,
  @flags int = 0,

  -- სალაროს საბუთებისათვის

  @cashier int = NULL,
  @chk_serie varchar(4) = NULL,
  @treasury_code varchar(9) = NULL,
  @tax_code_or_pid varchar(11) = NULL,

  -- საგადასახადო დავალებებისათვის

  @por smallint = NULL,

  @sender_bank_code TINTBANKCODE = NULL,
  @sender_bank_name varchar(100) = NULL,
  @sender_acc TINTACCOUNT = NULL,
  @sender_acc_name varchar(100) = NULL,
  @sender_tax_code varchar(11) = NULL,

  @receiver_bank_code TINTBANKCODE = NULL,
  @receiver_bank_name varchar(100) = NULL,
  @receiver_acc TINTACCOUNT = NULL,
  @receiver_acc_name varchar(100) = NULL,
  @receiver_tax_code varchar(11) = NULL,

  @extra_info varchar(250) = NULL,
  @ref_num varchar(100) = null,

  -- ლარის საგადასახადო დავალებებისათვის

  @rec_date smalldatetime = NULL,	-- საგ. დავალების რეგისტრაციის თარიღი
  @saxazkod varchar(9) = NULL,

  -- სავ. საგადასახადო დავალებებისათვის

  @intermed_bank_code TINTBANKCODE = NULL,
  @intermed_bank_name varchar(100) = NULL,
  @swift_text text = null,
  @cor_bank_code TINTBANKCODE = null,
  @cor_bank_name varchar(100) = null,

  -- სალაროს საბუთებისათვის და სავ. საგადასახადო დავალებებისათვის

  @first_name varchar(50) = null,
  @last_name varchar(50) = null, 
  @fathers_name varchar(50) = null, 
  @birth_date smalldatetime = null, 
  @birth_place varchar(100) = null, 
  @address_jur varchar(100) = null, 
  @address_lat varchar(100) = null,
  @country varchar(2) = null, 
  @passport_type_id tinyint = 0, 
  @passport varchar(50) = null, 
  @personal_id varchar(20) = null,
  @reg_organ varchar(50) = null,
  @passport_issue_dt smalldatetime = null,
  @passport_end_date smalldatetime = null,

  -- სხვა პარამეტრები

  @check_saldo bit = 1,		-- შეამოწმოს თუ არა მინ. ნაშთი
  @add_tariff bit = 1,		-- დაამატოს თუ არა ტარიფის საბუთი
  @info bit = 0,			-- რეალურად გატარდეს, თუ მხოლოდ ინფორმაციაა
  @lat bit = 0				-- გამოიტანოს თუ არა შეცდომები ინგლისურად
AS

SET NOCOUNT ON

IF @dept_no IS NULL
	SET @dept_no = dbo.user_dept_no(@user_id)

IF @debit_branch_id IS NULL
	SET @debit_branch_id  = dbo.dept_branch_id(@dept_no)
IF @credit_branch_id IS NULL
	SET @credit_branch_id  = dbo.dept_branch_id(@dept_no)

DECLARE 
	@r int,
	@debit_id int,
	@credit_id int

SET @debit_id = dbo.acc_get_acc_id (@debit_branch_id, @debit, @iso)
SET @credit_id = dbo.acc_get_acc_id (@credit_branch_id, @credit, @iso)

IF @debit_id IS NULL AND dbo.acc_can_auto_open_account (@debit_branch_id, @debit, @iso) = 1
BEGIN
	EXEC dbo.auto_open_account @debit_id OUTPUT, @debit_branch_id, @debit, @iso, @user_id
END

IF @credit_id IS NULL AND dbo.acc_can_auto_open_account (@credit_branch_id, @credit, @iso) = 1
BEGIN
	EXEC dbo.auto_open_account @credit_id OUTPUT, @credit_branch_id, @credit, @iso, @user_id
END

EXEC @r = dbo.ADD_DOC4
	@rec_id = @rec_id OUTPUT,
	@user_id = @user_id ,
	@owner = @owner ,
	@doc_type = @doc_type ,
	@doc_date = @doc_date,
	@doc_date_in_doc = @doc_date_in_doc ,
	@debit_id = @debit_id,
	@credit_id = @credit_id,
	@iso = @iso,
	@amount = @amount,
	@rec_state = @rec_state,
	@descrip = @descrip,
	@op_code = @op_code,
	@parent_rec_id = @parent_rec_id,
	@doc_num = @doc_num,
	@bnk_cli_id = @bnk_cli_id,
	@account_extra = @account_extra,
	@dept_no = @dept_no,
	@prod_id = @prod_id ,
	@foreign_id = @foreign_id,
	@channel_id = @channel_id ,
	@is_suspicious = @is_suspicious ,

	@relation_id = @relation_id ,
	@flags = @flags ,

	@cashier = @cashier ,
	@chk_serie = @chk_serie ,
	@treasury_code = @treasury_code ,
	@tax_code_or_pid = @tax_code_or_pid,

	@por = @por ,

	@sender_bank_code = @sender_bank_code ,
	@sender_bank_name = @sender_bank_name ,
	@sender_acc = @sender_acc ,
	@sender_acc_name = @sender_acc_name ,
	@sender_tax_code = @sender_tax_code ,

	@receiver_bank_code = @receiver_bank_code,
	@receiver_bank_name = @receiver_bank_name ,
	@receiver_acc = @receiver_acc ,
	@receiver_acc_name = @receiver_acc_name ,
	@receiver_tax_code = @receiver_tax_code ,

	@extra_info = @extra_info ,
	@ref_num = @ref_num ,

	@rec_date = @rec_date ,
	@saxazkod = @saxazkod ,

	@intermed_bank_code = @intermed_bank_code ,
	@intermed_bank_name = @intermed_bank_name ,
	@swift_text = @swift_text ,
	@cor_bank_code = @cor_bank_code ,
	@cor_bank_name = @cor_bank_name ,

	@first_name = @first_name,
	@last_name = @last_name ,
	@fathers_name = @fathers_name ,
	@birth_date = @birth_date ,
	@birth_place = @birth_place ,
	@address_jur = @address_jur ,
	@address_lat = @address_lat ,
	@country = @country ,
	@passport_type_id = @passport_type_id ,
	@passport = @passport ,
	@personal_id = @personal_id ,
	@reg_organ = @reg_organ ,
	@passport_issue_dt = @passport_issue_dt ,
	@passport_end_date = @passport_end_date ,

	@check_saldo = @check_saldo ,
	@add_tariff = @add_tariff ,
	@info = @info ,
	@lat = @lat 

RETURN @r
GO
