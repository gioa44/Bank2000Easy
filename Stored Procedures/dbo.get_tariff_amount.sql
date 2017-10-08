SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[get_tariff_amount]
	@result money OUTPUT,		-- აბრუნებს ტარიფის თანხას
	@tariff_id int,
	@tariff_doc_type smallint = null OUTPUT,	-- აბრუნებს ტარიფის საბუთის ტიპს (გადმოეცემა სწორი მნიშვნელობა)
	@tariff_op_code varchar(5) = null OUTPUT,	-- აბრუნებს ტარიფის საბუთის ოპერაციის კოდს (გადმოეცემა სწორი მნიშვნელობა)
	@client_no int,					-- კლიენტის ნომერი
	@descrip varchar(150) OUTPUT,	-- აბრუნებს ტარიფის დანიშნულება
	@user_id int,					-- ვინ ამატებს საბუთს
	@owner int = NULL,				-- პატრონი (გაჩუმებით = @user_id)
	@dept_no int = null,			-- ფილიალისა და განყოფილების №
	@doc_type smallint,				-- საბუთის ტიპი
	@doc_date smalldatetime,		-- ტრანზაქციის თარიღი
	@debit_id int OUTPUT,			-- დებეტის ანგარიში
	@credit_id int OUTPUT,			-- კრედიტის ანგარიში
	@iso TISO = 'GEL' OUTPUT,		-- ვალუტის კოდი
	@amount money,					-- თანხა
	@amount2 money = null,			-- კონვერტაციის თანხა 2
	@cash_amount money,				-- სალაროს დასაბეგრი თანხა
	@flags int OUTPUT,
	@op_code TOPCODE = '',			-- ოპერაციის კოდი
	@doc_num int = NULL,			-- საბუთის ნომერი ან კოდი
	@account_extra decimal(15,0)= NULL,		-- დამატებითი ანგარიშის მისათითებელი ველი
	@prod_id int = null OUTPUT,		-- პროდუქტის ნომერი, რომელიც ამატებს ამ საბუთს
	@foreign_id int = null OUTPUT,	-- დამატებითი გარე №
	@channel_id int = 0,			-- არხი, რომლითაც ემატება ეს საბუთი
	@cashier int = NULL,
	@receiver_bank_code varchar(37) = NULL,
	@det_of_charg char(3) = NULL,
	@rate_flags int,
	@info bit = 0					-- რეალურად გატარდეს, თუ მხოლოდ ინფორმაციაა
AS

SET @result = NULL

SET @op_code = ISNULL(@op_code, '')

DECLARE	
	@credit_id0 int
SET @credit_id0 = @credit_id

IF @doc_type BETWEEN 130 AND 149 -- Cash outcome document
	SET @cash_amount = @amount - ISNULL(@cash_amount, $0.0000)

DECLARE 
	@formula varchar(MAX),
	@r int

SELECT @formula = ISNULL(T.FORMULA, '') 
FROM dbo.TARIFF T (NOLOCK)
WHERE T.TARIFF = @tariff_id

SET @formula = ISNULL(@formula, '')
IF @formula = '' RETURN 0

DECLARE
	/* Operation types for Tariffs */
	@opMemo        smallint,
	@opPlatInner   smallint,
	@opPlatOuter   smallint,
	@opPlatVInner  smallint,
	@opPlatVOuter  smallint,
	@opKasRor      smallint,
	@opKasChe      smallint,
	@opConvert     smallint,
	@opOutOfBal    smallint,
	@opConvKasRor  smallint,
	@opPlatOuterBranch smallint,
	@opPlatOuterBranchV smallint

SET @opMemo        = 1
SET @opPlatInner   = 2
SET @opPlatOuter   = 3
SET @opPlatVInner  = 4
SET @opPlatVOuter  = 5
SET @opKasRor      = 6
SET @opKasChe      = 7
SET @opConvert     = 8
SET @opOutOfBal    = 9
SET @opConvKasRor  = 10
SET @opPlatOuterBranch = 11
SET @opPlatOuterBranchV = 12

DECLARE @op_type smallint

IF @doc_type in (14,16,20) 
				 SET @op_type = @opConvert ELSE /* opConvert */
IF @doc_type=98  SET @op_type = @opMemo ELSE /* opMemo */
IF @doc_type=100 SET @op_type = @opPlatInner ELSE /* opInnerPlat */
IF @doc_type=101 SET @op_type = @opPlatOuterBranch ELSE /* opOuterPlatBranch */
IF @doc_type=102 SET @op_type = @opPlatOuter ELSE /* opOuterPlat */
IF @doc_type=110 SET @op_type = @opPlatVInner ELSE /* opInnerPlatV */
IF @doc_type=111 SET @op_type = @opPlatOuterBranchV ELSE /* opOuterPlatBranchV */
IF @doc_type=112 SET @op_type = @opPlatVOuter ELSE /* opOuterPlatV */
IF @doc_type=130 SET @op_type = @opKasRor ELSE /* opKasRor */
IF @doc_type=132 SET @op_type = @opConvKasRor ELSE /* opConvKasRor */
IF @doc_type=140 SET @op_type = @opKasChe ELSE /* opKasChe */
IF @doc_type=200 SET @op_type = @opOutOfBal ELSE /* opOutOfBal */
				 SET @op_type = 0 

DECLARE 
	@sql_str nvarchar(MAX)

SET @sql_str = @formula
SET @result = NULL
SET @descrip = 'ÌÏÌÓÀáÖÒÄÁÉÓ % ÀÙÄÁÀ'
SET @flags = NULL
IF @op_type <> @opConvert 
	SET @amount2 = NULL

EXEC @r = dbo.ON_USER_GET_TARIFF_INFO
	@result = @result OUTPUT,		-- აბრუნებს ტარიფის თანხას
	@tariff_id = @tariff_id,
	@op_type = @op_type,
	@tariff_doc_type = @tariff_doc_type OUTPUT,	-- აბრუნებს ტარიფის საბუთის ტიპს (გადმოეცემა სწორი მნიშვნელობა)
	@tariff_op_code = @tariff_op_code OUTPUT,	-- აბრუნებს ტარიფის საბუთის ოპერაციის კოდს (გადმოეცემა სწორი მნიშვნელობა)
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
	@amount = @amount,	-- თანხა
	@amount2 = @amount2, -- კონვერტაციის თანხა 2
	@cash_amount = @cash_amount,
	@flags = @flags OUTPUT,
	@op_code = @op_code,
	@doc_num = @doc_num,
	@extra = @account_extra,
	@prod_id = @prod_id OUTPUT,
	@foreign_id = @foreign_id OUTPUT,
	@channel_id = @channel_id,
	@cashier = @cashier,
	@receiver_bank_code = @receiver_bank_code,
	@det_of_charg = @det_of_charg,
	@rate_flags = @rate_flags,
	@info = @info
IF @@ERROR <> 0 OR @r <> 0 RETURN 2

IF @result IS NULL
BEGIN
	EXEC @r = sp_executesql 
	  @sql_str,
	  N'
		@result money output,@tariff_id int,@op_type smallint,@descrip varchar(150) OUTPUT,
		@user_id int,@owner int,@dept_no int,@doc_type smallint,@doc_date smalldatetime,
		@debit_id int OUTPUT,@credit_id int OUTPUT,@iso char(3) OUTPUT,@amount money,@amount2 money,@cash_amount money,@flags int OUTPUT,
		@op_code varchar(5),@doc_num int,@extra decimal(15,0),@prod_id int OUTPUT,@foreign_id int OUTPUT,@channel_id int,@cashier int,@receiver_bank_code varchar(37),
		@det_of_charg char(3),@rate_flags int,@info bit,@client_no int,

		@opMemo smallint,@opPlatInner smallint,@opPlatOuter smallint,@opPlatVInner smallint,
		@opPlatVOuter smallint,@opKasRor smallint,@opKasChe smallint,@opConvert smallint,
		@opOutOfBal smallint,@opConvKasRor smallint,@opPlatOuterBranch smallint,@opPlatOuterBranchV smallint',

		@result output,@tariff_id,@op_type,@descrip OUTPUT,
		@user_id,@owner,@dept_no,@doc_type,@doc_date,
		@debit_id OUTPUT,@credit_id OUTPUT,@iso OUTPUT,@amount,@amount2,@cash_amount,@flags OUTPUT,
		@op_code,@doc_num,@account_extra,@prod_id OUTPUT,@foreign_id OUTPUT,@channel_id,@cashier,@receiver_bank_code,
		@det_of_charg,@rate_flags,@info,@client_no,

		@opMemo,@opPlatInner,@opPlatOuter,@opPlatVInner,
		@opPlatVOuter,@opKasRor,@opKasChe,@opConvert,
		@opOutOfBal,@opConvKasRor,@opPlatOuterBranch,@opPlatOuterBranchV
	IF @@ERROR <> 0 OR @r <> 0 RETURN 1
END

SET @result = ROUND(@result, 2)

IF ISNULL(@result, $0) <= 0 RETURN (0)
IF ISNULL(@iso, '') = '' BEGIN RAISERROR('ÀÒÀÓßÏÒÉ ×ÏÒÌÖËÀ. ÅÀËÖÔÉÓ ÊÏÃÉ ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ',16,1) RETURN (2) END

IF @debit_id IS NULL
BEGIN
	RAISERROR('<ERR>ÔÀÒÉ×ÉÓ ÃÀÌÀÔÄÁÀ ÅÄÒ áÄÒáÃÄÁÀ. ÃÄÁÄÔÉÓ ÀÍÂÀÒÉÛÉ ÝÀÒÉÄËÉÀ</ERR>', 16, 1)
	RETURN 1
END

IF @credit_id IS NULL 
BEGIN
	DECLARE @credit TACCOUNT
	SET @credit = dbo.acc_get_account(@credit_id0)
	IF dbo.acc_can_auto_open_account (@dept_no, @credit , @iso) = 1
	BEGIN
		EXEC @r = dbo.auto_open_account @credit_id OUTPUT, @dept_no, @credit , @iso, @user_id
		IF @@ERROR <> 0 OR @r <> 0 RETURN 3
	END
END

IF @credit_id IS NULL
BEGIN
	RAISERROR('<ERR>ÔÀÒÉ×ÉÓ ÃÀÌÀÔÄÁÀ ÅÄÒ áÄÒáÃÄÁÀ. ÊÒÄÃÉÔÉÓ ÀÍÂÀÒÉÛÉ ÝÀÒÉÄËÉÀ</ERR>', 16, 1)
	RETURN 2
END

SET @flags = ISNULL(@flags, 1)

RETURN (0)
GO
