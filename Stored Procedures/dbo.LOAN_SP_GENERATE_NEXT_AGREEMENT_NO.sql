SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[LOAN_SP_GENERATE_NEXT_AGREEMENT_NO]
	@agr_no varchar(100) OUTPUT,
	@template varchar(255),
	@date smalldatetime,
	@client_no int,
	@dept_no int,
	@ccy char(3),
	@lcd int,
	@lcm int,
	@lcy int,
	@lcc int,
	@lccp int,
	@lc int,
	@gc int
AS
--'[Y-4][T--][M][T--][D][T--][CCY][T-/][LCC-3]' -> '2007-03-20-USD/005'
DECLARE
	@I INT, @J INT, @L INT,
	@key varchar(20),
	@ind1 varchar(5),
	@ind2 varchar(20),
	@s varchar(20),
	@s1 varchar(20)	

SET @agr_no = ''

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
		SET @s = REVERSE(DATEPART(yyyy, @date))
		IF @ind2 = '2' SET @s = SUBSTRING(@s, 1, 2)
		SET @agr_no = @agr_no + REVERSE(@s)
	END
	ELSE
	IF UPPER(@ind1) = 'M' -- Month
	BEGIN
		SET @s = DATEPART(mm, @date)
		SET @agr_no = @agr_no + REPLICATE('0', 2 - LEN(@s)) + @s
	END
	ELSE
	IF UPPER(@ind1) = 'D' -- Dey
	BEGIN
		SET @s = DATEPART(dd, @date)
		SET @agr_no = @agr_no + REPLICATE('0', 2 - LEN(@s)) + @s
	END
	ELSE
	IF UPPER(@ind1) = 'T' --Free Text
		SET @agr_no = @agr_no + @ind2
	ELSE
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
		SET @agr_no = @agr_no + REVERSE(@s1)
	END
	ELSE
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
		SET @agr_no = @agr_no + REVERSE(@s1)
	END
	ELSE
	IF UPPER(@ind1) = 'LCD' -- Loan Count in Day
	BEGIN
		SET @s = REVERSE(convert(varchar(20), @lcd + 1))
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
		SET @agr_no = @agr_no + REVERSE(@s1)
	END
	ELSE
	IF UPPER(@ind1) = 'LCM' -- Loan Count in Month
	BEGIN
		SET @s = REVERSE(convert(varchar(20), @lcm + 1))
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
		SET @agr_no = @agr_no + REVERSE(@s1)
	END
	ELSE
	IF UPPER(@ind1) = 'LCY' -- Loan Count in Year
	BEGIN
		SET @s = REVERSE(convert(varchar(20), @lcy + 1))
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
		SET @agr_no = @agr_no + REVERSE(@s1)
	END
	ELSE
	IF (UPPER(@ind1) = 'LC')  -- Loans Count
	BEGIN
		SET @s = REVERSE(convert(varchar(20), @lc + 1))
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
		SET @agr_no = @agr_no + REVERSE(@s1)
	END
	ELSE
	IF (UPPER(@ind1) = 'GC')  -- Loans Count
	BEGIN
		SET @s = REVERSE(convert(varchar(20), @gc + 1))
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
		SET @agr_no = @agr_no + REVERSE(@s1)
	END
	ELSE
	IF UPPER(@ind1) = 'LCC' -- Client Loans Count
	BEGIN
		SET @s = REVERSE(convert(varchar(20), @lcc + 1))
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
		SET @agr_no = @agr_no + REVERSE(@s1)
	END
	ELSE
	IF UPPER(@ind1) = 'LCCP' -- Client Loans Count For Produc
	BEGIN
		SET @s = REVERSE(convert(varchar(20), @lccp + 1))
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
		SET @agr_no = @agr_no + REVERSE(@s1)
	END
	ELSE
	IF UPPER(@ind1) = 'CCY' -- CURRENCY
		SET @agr_no = @agr_no + @ccy
END
RETURN 0

ERR:
	SET @agr_no = '!!!ERROR!!!'
	RETURN 1
GO
