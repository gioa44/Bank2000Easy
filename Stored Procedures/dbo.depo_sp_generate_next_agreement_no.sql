SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_generate_next_agreement_no]
	@agreement_no varchar(100) OUTPUT,
	@template varchar(255),
	@date smalldatetime,
	@client_no int,			--> [CN] - Client No
	@dept_no int,			--> [DP] - Dept No
	@ccy char(3),			--> [CCY] - Currency
	@prod_no int,			--> [PN] - Product No (4 digict)
	@dcd int,				--> [DCD] - Deposits Count in Day
	@dcm int,				--> [DCM] - Deposits Count in Months
	@dcy int,				--> [DCY] - Deposits Count in Months
	@dcc int,				--> [DCC] - Client Deposits Count
	@dccp int,				--> [DCCP] - Client Deposits Count For Product
	@dccd int,				--> [DCCD] - Client Deposits Count For Date
	@dc int,				--> [DC] - All Deposit Count
	@dcp int				--> [DCP] - All Deposit Count For Product
AS
--'[Y-4][T--][M][T--][D][T--][CCY][T-/][DCC-3]' -> '2007-03-20-USD/005'
DECLARE
	@I INT, @J INT, @L INT,
	@key varchar(20),
	@ind1 varchar(5),
	@ind2 varchar(20),
	@s varchar(20),
	@s1 varchar(20)	

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
		SET @s = REVERSE(DATEPART(yyyy, @date))
		IF @ind2 = '2' SET @s = SUBSTRING(@s, 1, 2)
		SET @agreement_no = @agreement_no + REVERSE(@s)
	END
	IF UPPER(@ind1) = 'M' -- Month
	BEGIN
		SET @s = DATEPART(mm, @date)
		SET @agreement_no = @agreement_no + REPLICATE('0', 2 - LEN(@s)) + @s
	END
	IF UPPER(@ind1) = 'D' -- Dey
	BEGIN
		SET @s = DATEPART(dd, @date)
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
	IF UPPER(@ind1) = 'PN' -- PRODUCT NO
	BEGIN
		SET @s = REVERSE(convert(varchar(4), @prod_no))
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
	IF UPPER(@ind1) = 'DCD' -- Deposit Count in Day
	BEGIN
		SET @s = REVERSE(convert(varchar(20), @dcd + 1))
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
	IF UPPER(@ind1) = 'DCM' -- Deposit Count in Month
	BEGIN
		SET @s = REVERSE(convert(varchar(20), @dcm + 1))
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
	IF UPPER(@ind1) = 'DCY' -- Deposit Count in Year
	BEGIN
		SET @s = REVERSE(convert(varchar(20), @dcy + 1))
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
	IF UPPER(@ind1) = 'DC' -- Deposit Count
	BEGIN
		SET @s = REVERSE(convert(varchar(20), @dc + 1))
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
	IF UPPER(@ind1) = 'DCP' -- Deposit Count Product
	BEGIN
		SET @s = REVERSE(convert(varchar(20), @dcp + 1))
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
	IF UPPER(@ind1) = 'DCC' -- Deposit Client Count
	BEGIN
		SET @s = REVERSE(convert(varchar(20), @dcc + 1))
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
	IF UPPER(@ind1) = 'DCCP' -- Client Deposit Count For Product
	BEGIN
		SET @s = REVERSE(convert(varchar(20), @dccp + 1))
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
	IF UPPER(@ind1) = 'DCCD' -- Client Deposit Count For Date
	BEGIN
		SET @s = REVERSE(convert(varchar(20), @dccd + 1))
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
	SET @agreement_no = '!!!ERROR!!!'
	RETURN 1

GO
