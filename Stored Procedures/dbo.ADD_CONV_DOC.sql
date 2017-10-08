SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ADD_CONV_DOC]
  @rec_id_1 int OUTPUT,		-- რა შიდა ნომრით დაემატა 1 საბუთი
  @rec_id_2 int OUTPUT,		-- რა შიდა ნომრით დაემატა 2 საბუთი
  @user_id int,				-- ვინ ამატებს საბუთს
  @owner int = NULL,		-- პატრონი (გაჩუმებით = @user_id)
  @iso_d TISO,				-- ვალუტის კოდი 1
  @iso_c TISO,				-- ვალუტის კოდი 2
  @amount_d money,			-- თანხა 1
  @amount_c money,			-- თანხა 2
  @debit_branch_id int = null,				-- დებეტის ფილიალი
  @debit TACCOUNT,			-- დებეტის ანგარიში
  @credit_branch_id int = null,				-- კრედიტის ფილიალი
  @credit TACCOUNT,			-- კრედიტის ანგარიში
  @doc_date smalldatetime,	-- ტრანზაქციის თარიღი
  @op_code TOPCODE = 'FX',	-- ოპერაციის კოდი, უნაღდო კონვერტაციის შემთხვევაში
  @doc_num int = NULL,		-- საბუთის ნომერი ან კოდი
  @account_extra TACCOUNT = NULL,	-- დამატებითი ანგარიშის მისათითებელი ველი

  @is_kassa bit = 0,		-- არის თუ არა სალაროს კონვერტაცია
  
  @descrip1 varchar(150),	-- დანიშნულება 1
  @descrip2 varchar(150),	-- დანიშნულება 2
  @rec_state tinyint = 0,	-- სტატუსი
  @bnk_cli_id int = null,	-- ბანკ-კლიენტის მომხმარებლის №
  @par_rec_id int = -1,		-- ზემდგომი საბუთის ნომერი
								--  0: არ ყავს ზემდგომი, არ  ყავს შვილი
								-- -1: ყავს შვილი (იშლება ერთად, ავტორიზდება ერთად)
								-- -2: ყავს შვილი (იშლება ერთად, ავტორიზდება ცალ-ცალკე)
								-- -3: ყავს შვილი (იშლება ცალ-ცალკე, ავტორიზდება ცალ-ცალკე)

  @dept_no int = null,		-- ფილიალისა და განყოფილების №
  @prod_id int = null,		-- პროდუქტის ნომერი, რომელიც ამატებს ამ საბუთს
  @foreign_id int = null,	-- დამტებითი გარე №
  @channel_id int = 0,		-- არხი, რომლითაც ემატება ეს საბუთი
  @is_suspicious bit = 0,	-- არის თუ არა საეჭვო ეს საბუთი

  -- ინფორმაცია კონვერტაციაზე

  @rate_items int = Null,
  @rate_amount money = Null,
  @rate_reverse bit = 0,
  @rate_flags int = 0,
  @tariff_kind bit = 0,
  @lat_descrip bit = 0,

  @client_no int = NULL,
  @rate_client_no int = NULL,

  -- საპასპორტო მონაცემები

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

SET @debit_id = dbo.acc_get_acc_id (@debit_branch_id, @debit, @iso_d)
SET @credit_id = dbo.acc_get_acc_id (@credit_branch_id, @credit, @iso_c)

EXEC @r = dbo.ADD_CONV_DOC4
  @rec_id_1 = @rec_id_1  OUTPUT,        
  @rec_id_2 = @rec_id_2 OUTPUT,        
  @user_id = @user_id ,                
  @owner = @owner , 
  @iso_d = @iso_d ,              
  @iso_c = @iso_c,              
  @amount_d = @amount_d,          
  @amount_c = @amount_c ,   
  @debit_id = @debit_id ,
  @credit_id = @credit_id ,
  @doc_date = @doc_date ,   
  @op_code = @op_code ,   
  @doc_num = @doc_num ,   
  @account_extra = @account_extra ,   

  @is_kassa = @is_kassa ,   
  
  @descrip1 = @descrip1 ,   
  @descrip2 = @descrip2 ,   
  @rec_state = @rec_state ,   
  @bnk_cli_id = @bnk_cli_id ,   
  @par_rec_id = @par_rec_id ,   

  @dept_no = @dept_no ,   
  @prod_id = @prod_id ,   
  @foreign_id = @foreign_id ,
  @channel_id = @channel_id ,   
  @is_suspicious = @is_suspicious ,   

  @rate_items = @rate_items ,
  @rate_amount = @rate_amount ,
  @rate_reverse = @rate_reverse ,
  @rate_flags = @rate_flags ,
  @tariff_kind = @tariff_kind ,
  @lat_descrip = @lat_descrip ,

  @client_no = @client_no ,
  @rate_client_no = @rate_client_no ,

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
