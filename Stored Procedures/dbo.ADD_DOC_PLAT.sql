SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- პროცედურა საგადასახადო საბუთის დასამატებლად

CREATE PROCEDURE [dbo].[ADD_DOC_PLAT]
  @rec_id int OUTPUT,			-- რა შიდა ნომრით დაემატა საბუთი
  @user_id int,					-- ვინ ამატებს საბუთს
  @owner int = NULL,			-- პატრონი (გაჩუმებით = @user_id)
  @doc_date smalldatetime,		-- ტრანზაქციის თარიღი
  @doc_date_in_doc smalldatetime = NULL,	-- საბუთის თარიღი, ან სხვა თარიღი

  @debit_branch_id int = NULL,	-- დებეტის ფილიალი
  @debit TACCOUNT = NULL,		-- დებეტის ანგარიში
  @credit_branch_id int = NULL,	-- კრედიტის ფილიალი
  @credit TACCOUNT = NULL,		-- კრედიტის ანგარიში

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
  @relation_id int = NULL,
  @flags int = 0,

  @doc_num int = NULL,			-- საბუთის ნომერი ან კოდი
  @bnk_cli_id int = NULL,		-- ბანკ-კლიენტის მომხმარებლის №
  @account_extra TACCOUNT = NULL,	-- დამატებითი ანგარიშის მისათითებელი ველი
  @dept_no int = null,				-- ფილიალისა და განყოფილების №
  @prod_id int = null,				-- პროდუქტის ნომერი, რომელიც ამატებს ამ საბუთს
  @foreign_id int = null,			-- დამტებითი გარე №
  @channel_id int = 0,				-- არხი, რომლითაც ემატება ეს საბუთი
  @is_suspicious bit = 0,			-- არის თუ არა საეჭვო ეს საბუთი

  -- საგადასახადო დავალებებისათვის

  @doc_type smallint = null,	-- თუ ცარიელია, არ გამოთვალოს თვითონ

  @sender_bank_code TGEOBANKCODE = NULL,
  @sender_acc TINTACCOUNT,
  @sender_acc_name varchar(100) = NULL,
  @sender_tax_code varchar(11) = NULL,
  
  @receiver_bank_code TGEOBANKCODE = NULL,
  @receiver_acc TINTACCOUNT,
  @receiver_acc_name varchar(100) = NULL,
  @receiver_tax_code varchar(11) = NULL,

  @ref_num varchar(100) = null,
  @extra_info varchar(250) = NULL,

  -- ლარის საგადასახადო დავალებებისათვის

  @rec_date smalldatetime = NULL,	-- საგ. დავალების რეგისტრაციის თარიღი
  @saxazkod varchar(9) = NULL,

  -- სხვა პარამეტრები

  @check_saldo bit = 1,		-- შეამოწმოს თუ არა მინ. ნაშთი
  @add_tariff bit = 1,		-- დაამატოს თუ არა ტარიფის საბუთი
  @info bit = 0,			-- რეალურად გატარდეს, თუ მხოლოდ ინფორმაციაა
  @lat bit = 0				-- გამოიტანოს თუ არა შეცდომები ინგლისურად
AS

SET NOCOUNT ON

DECLARE 
	@our_branch_id int

IF @dept_no IS NULL
	SET @dept_no = dbo.user_dept_no(@user_id)
SET @our_branch_id = dbo.dept_branch_id(@dept_no)


DECLARE 
	@r int,
	@debit_id int,
	@credit_id int,
	@sender_bank_name varchar(100),
	@receiver_bank_name varchar(100)

---

IF @sender_bank_code IS NULL OR @receiver_bank_code IS NULL
BEGIN
	SELECT 
		@sender_bank_code = CASE WHEN @sender_bank_code IS NULL THEN CODE9 ELSE @sender_bank_code END,
		@receiver_bank_code  =  CASE WHEN @receiver_bank_code IS NULL THEN CODE9 ELSE @receiver_bank_code END
	FROM dbo.DEPTS (NOLOCK)
	WHERE DEPT_NO = @dept_no
END

IF dbo.bank_is_geo_bank_in_our_db(@sender_bank_code) <> 0
BEGIN
	IF @debit IS NULL
		SET @debit  = convert(decimal(15,0), @sender_acc)

	SELECT TOP 1 @sender_bank_name = D.DESCRIP, @debit_branch_id = CASE WHEN @debit_branch_id IS NULL THEN D.DEPT_NO ELSE @debit_branch_id END
	FROM dbo.ACCOUNTS A (NOLOCK)
			INNER JOIN dbo.DEPTS D ON D.BRANCH_ID = A.BRANCH_ID
	WHERE D.CODE9 = @sender_bank_code AND D.IS_DEPT = 0 AND A.ACCOUNT = @debit AND A.ISO = @iso AND NOT A.REC_STATE IN (2, 128)
	ORDER BY D.DEPT_NO

	SET @debit_id = dbo.acc_get_acc_id (@debit_branch_id, @debit, @iso)

	IF @sender_acc_name IS NULL
		SELECT @sender_acc_name = DESCRIP
		FROM dbo.ACCOUNTS (NOLOCK)
		WHERE ACC_ID = @debit_id

	IF @sender_tax_code IS NULL
		SELECT @sender_tax_code = CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END
		FROM dbo.CLIENTS C (NOLOCK)
			INNER JOIN dbo.ACCOUNTS A (NOLOCK) ON A.CLIENT_NO = C.CLIENT_NO
		WHERE A.ACC_ID = @debit_id
END
ELSE
BEGIN
	SELECT @sender_bank_name = DESCRIP
	FROM dbo.BANKS (NOLOCK)
	WHERE CODE9 = @sender_bank_code

	IF @@ROWCOUNT = 0
	BEGIN
		IF @lat = 0 
			RAISERROR('<ERR>ÁÀÍÊÉ %d ÀÒ ÌÏÉÞÄÁÍÀ</ERR>',16,1,@sender_bank_code)
		ELSE RAISERROR('<ERR>Bank %d not found</ERR>',16,1,@sender_bank_code);
		RETURN (203)
	END

	IF @debit IS NULL
       EXEC dbo.GET_SETTING_ACC 'CORR_ACC_NP', @debit OUTPUT

	SET @debit_id = dbo.acc_get_acc_id (ISNULL(@debit_branch_id, 0), @debit, @iso) -- ÌáÏËÏÃ ÓÀÈÀÏ
END

---

IF dbo.bank_is_geo_bank_in_our_db(@receiver_bank_code) <> 0
BEGIN
	IF @credit IS NULL
		SET @credit = convert(decimal(15,0), @receiver_acc)

	SELECT TOP 1 @credit_id = A.ACC_ID
	FROM dbo.ACCOUNTS A
		INNER JOIN dbo.DEPTS D ON D.BRANCH_ID = A.BRANCH_ID
	WHERE D.CODE9 = @receiver_bank_code AND D.IS_DEPT = 0 AND A.ACCOUNT = @credit AND A.ISO = @iso AND NOT A.REC_STATE IN (2, 128)
	ORDER BY D.DEPT_NO

	SELECT @receiver_bank_name = DESCRIP
	FROM dbo.BANKS
	WHERE CODE9 = @receiver_bank_code 

	IF @receiver_acc_name IS NULL
		SELECT @receiver_acc_name = DESCRIP
		FROM dbo.ACCOUNTS (NOLOCK)
		WHERE ACC_ID = @credit_id

	IF @receiver_tax_code IS NULL
		SELECT @receiver_tax_code = CASE WHEN ISNULL(C.TAX_INSP_CODE, '') <> '' THEN C.TAX_INSP_CODE ELSE C.PERSONAL_ID END
		FROM dbo.CLIENTS C (NOLOCK)
			INNER JOIN dbo.ACCOUNTS A (NOLOCK) ON A.CLIENT_NO = C.CLIENT_NO
		WHERE A.ACC_ID = @credit_id
END
ELSE
BEGIN
	DECLARE 
		@bank_rec_state int,
		@head_branch_dept_no int

	SELECT @receiver_bank_name = DESCRIP, @bank_rec_state = REC_STATE
	FROM dbo.BANKS (NOLOCK)
	WHERE CODE9 = @receiver_bank_code

	IF @@ROWCOUNT = 0
	BEGIN
		IF @lat = 0 
			RAISERROR('<ERR>ÁÀÍÊÉ %d ÀÒ ÌÏÉÞÄÁÍÀ</ERR>',16,1,@receiver_bank_code)
		ELSE RAISERROR('<ERR>Bank %d not found</ERR>',16,1,@receiver_bank_code);
		RETURN (203)
	END
	
	IF @bank_rec_state = 2
	BEGIN
		IF @lat = 0
			RAISERROR('<ERR>ÀÌ ÁÀÍÊÛÉ ×ÖËÉÓ ÂÀÃÀÒÉÝáÅÀ ÀÒ ÛÄÉÞËÄÁÀ</ERR>',16,1)
		ELSE RAISERROR('<ERR>Money transfer to this bank is disabled</ERR>',16,1)
		RETURN (204)
	END

	IF @credit IS NULL
       EXEC dbo.GET_SETTING_ACC 'CORR_ACC_NA', @credit OUTPUT
	IF @credit_branch_id IS NULL
		EXEC dbo.GET_SETTING_INT 'HEAD_BRANCH_DEPT_NO', @head_branch_dept_no OUTPUT

	SET @credit_id = dbo.acc_get_acc_id (ISNULL(@credit_branch_id, @head_branch_dept_no), @credit, @iso) -- ÌáÏËÏÃ ÓÀÈÀÏ

	IF @iso <> 'GEL' OR dbo.is_trasury_transfer (@receiver_bank_code, @receiver_acc) = 0
		SET @saxazkod = NULL
END

--

IF @doc_type IS NULL
BEGIN
	IF @debit_branch_id = @credit_branch_id /* internal transfer */
		SET @doc_type = 100
	ELSE
	IF @debit_branch_id = @our_branch_id
	BEGIN
		SET @doc_type = 102
		IF @credit_branch_id IS NOT NULL OR EXISTS (SELECT * FROM dbo.DEPTS (NOLOCK) WHERE CODE9 = @receiver_bank_code)
			SET @doc_type = 101
	END
	ELSE
	IF @credit_branch_id = @our_branch_id
	BEGIN
		SET @doc_type = 104
		IF @debit_branch_id IS NOT NULL OR EXISTS (SELECT * FROM dbo.DEPTS (NOLOCK) WHERE CODE9 = @sender_bank_code)
			SET @doc_type = 103
	END
	ELSE
		SET @doc_type = 106
END

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

EXEC @r = dbo.ADD_DOC4
  @rec_id = @rec_id OUTPUT,			
  @user_id = @user_id,
  @owner = @owner,
  @doc_type = @doc_type,
  @doc_date = @doc_date,
  @doc_date_in_doc = @doc_date_in_doc,
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
  @prod_id = @prod_id,
  @foreign_id = @foreign_id,
  @channel_id = @channel_id,
  @is_suspicious = @is_suspicious,
  @relation_id = @relation_id,
  @flags = @flags,

  @sender_bank_code = @sender_bank_code,
  @sender_bank_name = @sender_bank_name,
  @sender_acc = @sender_acc,
  @sender_acc_name = @sender_acc_name,
  @sender_tax_code = @sender_tax_code,

  @receiver_bank_code = @receiver_bank_code,
  @receiver_bank_name = @receiver_bank_name,
  @receiver_acc = @receiver_acc,
  @receiver_acc_name = @receiver_acc_name,
  @receiver_tax_code = @receiver_tax_code,

  @ref_num = @ref_num,
  @extra_info = @extra_info,

  @rec_date = @rec_date,	-- საგ. დავალების რეგისტრაციის თარიღი
  @saxazkod = @saxazkod,

  @check_saldo = @check_saldo,		-- შეამოწმოს თუ არა მინ. ნაშთი
  @add_tariff = @add_tariff,		-- დაამატოს თუ არა ტარიფის საბუთი
  @info = @info,			-- რეალურად გატარდეს, თუ მხოლოდ ინფორმაციაა
  @lat = @lat				-- გამოიტანოს თუ არა შეცდომები ინგლისურად

IF @@ERROR<>0 OR @r<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 31 END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN
RETURN (0)
GO
