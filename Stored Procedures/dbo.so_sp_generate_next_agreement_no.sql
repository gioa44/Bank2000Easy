SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[so_sp_generate_next_agreement_no]
	@agreement_no varchar(100) OUTPUT,
	@template varchar(255) = NULL,
	@task_id int
AS

--'[Y-4][T--][M][T--][D][T--][CCY][T-/][TCC-3]' -> '2007-03-20-USD/005'
DECLARE
	@I INT, @J INT, @L INT,
	@key varchar(20),
	@ind1 varchar(5),
	@ind2 varchar(20),
	@s varchar(20),
	@s1 varchar(20)

DECLARE
	@start_date smalldatetime,
	@client_no int,			--> [CN] - Client No
	@dept_no int,			--> [DP] - Dept No
	@ccy char(3),			--> [CCY] - Currency
	@product_id int,		--> [PN] - Product No (4 digit)
	@tcd int,				--> [TCD] - Count in Day
	@tcm int,				--> [TCM] - Task Count in Months
	@tcy int,				--> [TCY] - Task Count in Year
	@tcc int,				--> [TCC] - Client Task Count
	@tccp int,				--> [TCCP] - Client Task Count For Product
	@tccd int,				--> [TCCD] - Client Task Count For Date
	@tc int,				--> [TC] - All Task Count
	@tcp int				--> [TCP] - All Task Count For Product

SELECT 
	@product_id = PRODUCT_ID,
	@client_no = CLIENT_NO,
	@start_date = [START_DATE],
	@dept_no = [DEPT_NO],
	@ccy = ''
FROM dbo.SO_TASKS (NOLOCK)
WHERE ID = @task_id

IF @@ROWCOUNT = 0
BEGIN
  RAISERROR('SO ÃÀÅÀËÄÁÀ ÀÒ ÌÏÉÞÄÁÍÀ!', 16, 1)
  RETURN -1
END

SELECT @template = ISNULL(@template, AGREEMENT_TEMPLATE) 
FROM dbo.SO_PRODUCTS (NOLOCK)
WHERE ID = @product_id

IF ISNULL(@template, '') = ''
BEGIN
  RAISERROR('ÐÒÏÃÖØÔÛÉ ÛÀÁËÏÍÉ ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ!', 16, 1)
  RETURN -1
END

IF CHARINDEX('TCD', UPPER(@template)) <> 0
	SELECT @tcd = COUNT(*) FROM dbo.SO_TASKS
	WHERE [START_DATE] = @start_date

IF CHARINDEX('TCM', UPPER(@template)) <> 0
	SELECT @tcm = COUNT(*) FROM dbo.SO_TASKS
	WHERE DATEPART(yyyy, [START_DATE]) = DATEPART(yyyy, @start_date) AND DATEPART(mm, [START_DATE]) = DATEPART(mm, @start_date)

IF CHARINDEX('TCY', UPPER(@template)) <> 0
	SELECT @tcy = COUNT(*) FROM dbo.SO_TASKS
	WHERE DATEPART(yyyy, [START_DATE]) = DATEPART(yyyy, [START_DATE])

IF CHARINDEX('TCC', UPPER(@template)) <> 0
	SELECT @tcc = COUNT(*) FROM dbo.SO_TASKS
	WHERE CLIENT_NO = @client_no

IF CHARINDEX('TCCP', UPPER(@template)) <> 0
	SELECT @tccp = COUNT(*) FROM dbo.SO_TASKS
	WHERE PRODUCT_ID = @product_id AND CLIENT_NO = @client_no
	
IF CHARINDEX('TCCD', UPPER(@template)) <> 0
	SELECT @tccd = COUNT(*) FROM dbo.SO_TASKS (NOLOCK)
	WHERE CLIENT_NO = @client_no AND [START_DATE] = @start_date
	
IF CHARINDEX('TC', UPPER(@template)) <> 0
	SELECT @tc = COUNT(*) FROM dbo.SO_TASKS

IF CHARINDEX('TCP', UPPER(@template)) <> 0
	SELECT @tcp = COUNT(*) FROM dbo.SO_TASKS
	WHERE PRODUCT_ID = @product_id

SET @agreement_no = ''

WHILE @template <> ''
BEGIN
	SET @ind1 = ''
	SET @ind2 = ''
	SET @I = CHARINDEX('[', @template)
	IF @I = 0 GOTO ERR
	SET @J = CHARINDEX(']', @template)
	IF @J = 0 GOTO ERR
	SET @key = SUBSTRING(@template, @I + 1, @J - 2)
	SET @template = SUBSTRING(@template, @J + 1, 100)
	SET @I = CHARINDEX('-', @key)
	IF @I <> 0
	BEGIN
		SET @ind1 = SUBSTRING(@key, 1, @I - 1)
		SET @ind2 = SUBSTRING(@key, @I + 1, 100)
	END
	ELSE
		SET @ind1 = @key
		
	IF UPPER(@ind1) = 'Y' -- Year
	BEGIN
		SET @s = REVERSE(DATEPART(yyyy, @start_date))
		IF @ind2 = '2' SET @s = SUBSTRING(@s, 1, 2)
		SET @agreement_no = @agreement_no + REVERSE(@s)
	END
	IF UPPER(@ind1) = 'M' -- Month
	BEGIN
		SET @s = DATEPART(mm, @start_date)
		SET @agreement_no = @agreement_no + REPLICATE('0', 2 - LEN(@s)) + @s
	END
	IF UPPER(@ind1) = 'D' -- Dey
	BEGIN
		SET @s = DATEPART(dd, @start_date)
		SET @agreement_no = @agreement_no + REPLICATE('0', 2 - LEN(@s)) + @s
	END
	IF UPPER(@ind1) = 'T' --Free Text
		SET @agreement_no = @agreement_no + @ind2
	IF UPPER(@ind1) = 'CN' -- CLIENT NO
	BEGIN
		SET @s = REVERSE(convert(varchar(20), @client_no))
		SET @s1 = ''
		SET @J = convert(int, @ind2)
		SET @I = 1
		WHILE @I <= @J
		BEGIN
			IF @I <= LEN(@s)
				SET @s1 = @s1 + SUBSTRING(@s, @I, 1)
			ELSE
				SET @s1 = @s1 + '0'
			SET @I = @I + 1
		END
		SET @agreement_no = @agreement_no + REVERSE(@s1)
	END
	IF UPPER(@ind1) = 'PN' -- PRODUCT ID
	BEGIN
		SET @s = REVERSE(convert(varchar(4), @product_id))
		SET @s1 = ''
		SET @J = 4 --convert(int, @ind2)
		SET @I = 1
		WHILE @I <= @J
		BEGIN
			IF @I <= LEN(@s)
				SET @s1 = @s1 + SUBSTRING(@s, @I, 1)
			ELSE
				SET @s1 = @s1 + '0'
			SET @I = @I + 1
		END
		SET @agreement_no = @agreement_no + REVERSE(@s1)
	END
	IF UPPER(@ind1) = 'DP' -- DEPT NO
	BEGIN
		SET @s = REVERSE(convert(varchar(20), @dept_no))
		SET @s1 = ''
		SET @J = convert(int, @ind2)
		SET @I = 1
		WHILE @I <= @J
		BEGIN
			IF @I <= LEN(@s)
				SET @s1 = @s1 + SUBSTRING(@s, @I, 1)
			ELSE
				SET @s1 = @s1 + '0'
			SET @I = @I + 1
		END
		SET @agreement_no = @agreement_no + REVERSE(@s1)
	END
	IF UPPER(@ind1) = 'TCD' -- Task Count in Day
	BEGIN
		SET @s = REVERSE(convert(varchar(20), @tcd + 1))
		SET @s1 = ''
		SET @J = convert(int, @ind2)
		SET @I = 1
		WHILE @I <= @J
		BEGIN
			IF @I <= LEN(@s)
				SET @s1 = @s1 + SUBSTRING(@s, @I, 1)
			ELSE
				SET @s1 = @s1 + '0'
			SET @I = @I + 1
		END
		SET @agreement_no = @agreement_no + REVERSE(@s1)
	END
	IF UPPER(@ind1) = 'TCM' -- Task Count in Month
	BEGIN
		SET @s = REVERSE(convert(varchar(20), @tcm + 1))
		SET @s1 = ''
		SET @J = convert(int, @ind2)
		SET @I = 1
		WHILE @I <= @J
		BEGIN
			IF @I <= LEN(@s)
				SET @s1 = @s1 + SUBSTRING(@s, @I, 1)
			ELSE
				SET @s1 = @s1 + '0'
			SET @I = @I + 1
		END
		SET @agreement_no = @agreement_no + REVERSE(@s1)
	END
	IF UPPER(@ind1) = 'TCY' -- Task Count in Year
	BEGIN
		SET @s = REVERSE(convert(varchar(20), @tcy + 1))
		SET @s1 = ''
		SET @J = convert(int, @ind2)
		SET @I = 1
		WHILE @I <= @J
		BEGIN
			IF @I <= LEN(@s)
				SET @s1 = @s1 + SUBSTRING(@s, @I, 1)
			ELSE
				SET @s1 = @s1 + '0'
			SET @I = @I + 1
		END
		SET @agreement_no = @agreement_no + REVERSE(@s1)
	END
	IF UPPER(@ind1) = 'TC' -- Task Count
	BEGIN
		SET @s = REVERSE(convert(varchar(20), @tc + 1))
		SET @s1 = ''
		SET @J = convert(int, @ind2)
		SET @I = 1
		WHILE @I <= @J
		BEGIN
			IF @I <= LEN(@s)
				SET @s1 = @s1 + SUBSTRING(@s, @I, 1)
			ELSE
				SET @s1 = @s1 + '0'
			SET @I = @I + 1
		END
		SET @agreement_no = @agreement_no + REVERSE(@s1)
	END
	IF UPPER(@ind1) = 'TCP' -- Task Count For Product
	BEGIN
		SET @s = REVERSE(convert(varchar(20), @tcp + 1))
		SET @s1 = ''
		SET @J = convert(int, @ind2)
		SET @I = 1
		WHILE @I <= @J
		BEGIN
			IF @I <= LEN(@s)
				SET @s1 = @s1 + SUBSTRING(@s, @I, 1)
			ELSE
				SET @s1 = @s1 + '0'
			SET @I = @I + 1
		END
		SET @agreement_no = @agreement_no + REVERSE(@s1)
	END
	IF UPPER(@ind1) = 'TCC' -- Client's Task Count
	BEGIN
		SET @s = REVERSE(convert(varchar(20), @tcc + 1))
		SET @s1 = ''
		SET @J = convert(int, @ind2)
		SET @I = 1
		WHILE @I <= @J
		BEGIN
			IF @I <= LEN(@s)
				SET @s1 = @s1 + SUBSTRING(@s, @I, 1)
			ELSE
				SET @s1 = @s1 + '0'
			SET @I = @I + 1
		END
		SET @agreement_no = @agreement_no + REVERSE(@s1)
	END
	IF UPPER(@ind1) = 'TCCP' -- Client's Task Count For Product
	BEGIN
		SET @s = REVERSE(convert(varchar(20), @tccp + 1))
		SET @s1 = ''
		SET @J = convert(int, @ind2)
		SET @I = 1
		WHILE @I <= @J
		BEGIN
			IF @I <= LEN(@s)
				SET @s1 = @s1 + SUBSTRING(@s, @I, 1)
			ELSE
				SET @s1 = @s1 + '0'
			SET @I = @I + 1
		END
		SET @agreement_no = @agreement_no + REVERSE(@s1)
	END
	IF UPPER(@ind1) = 'TCCD' -- Client's Task Count For Date
	BEGIN
		SET @s = REVERSE(convert(varchar(20), @tccd + 1))
		SET @s1 = ''
		SET @J = convert(int, @ind2)
		SET @I = 1
		WHILE @I <= @J
		BEGIN
			IF @I <= LEN(@s)
				SET @s1 = @s1 + SUBSTRING(@s, @I, 1)
			ELSE
				SET @s1 = @s1 + '0'
			SET @I = @I + 1
		END
		SET @agreement_no = @agreement_no + REVERSE(@s1)
	END
	IF UPPER(@ind1) = 'CCY' -- CURRENCY
		SET @agreement_no = @agreement_no + @ccy
END
RETURN 0

ERR:
	SET @agreement_no = '!!!TEMPLATE ERROR!!!'
	RETURN 1
GO
