SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* 
  N - number
  n - number or blank
  {C} = Currency (GEL -> 0, ELSE -> 1)
  {An} = Balance Account, where n = (1,2,3,4,5,6)
  {Bn} = Branch Number, where n = 1...9
  {Dn} = Dept Number, where n = 1...9
  {Ln} = Client Number, where n = 1...6
  {Pn} = Product Number, where n = 1...6


  EXAMPLE:
    Balance Account = 3601.78
    Branch No = 15
	Dept No = 15
    Client No = 234
    Currency = USD

  {C} = 1
  {A1} = 3
  {A2} = 6
  {A3} = 0
  {A4} = 1
  {A5} = 7
  {A6} = 8
  {B1} = 5
  {B2} = 15
  {B3} = 015
  {B4} = 0015
  {L1} = 4
  {L2} = 34
  {L3} = 234
  {L4} = 0234
  {L5} = 00234
*/

CREATE PROCEDURE [dbo].[GET_NEXT_ACC_NUM_NEW] 
	@bal_acc TBAL_ACC, 
	@branch_id int, 
    @dept_no int = null, 
	@client_no int = null, 
	@iso TISO, 
	@product_no int = null, 
	@template varchar(100) = null,
	@acc TACCOUNT OUTPUT,
	@user_id int = NULL,
	@return_row bit = 1
AS

SET NOCOUNT ON

DECLARE @new_acc_unique int

EXEC dbo.GET_SETTING_INT 'OPT_NEW_ACC_UNIQUE', @new_acc_unique OUTPUT


IF ISNULL(@template,'') = ''
BEGIN
	SELECT @template = VALS
	FROM dbo.INI_STR (NOLOCK)
	WHERE IDS = 'ACC_TEMPLATE'
	IF ISNULL(@template,'')  = ''
		SET @template = 'n{A1}{A2}{A3}{A4}NNNNN'
END

DECLARE @acc0 TACCOUNT

SET @acc = ISNULL(@acc, 0)

IF CHARINDEX(',', @template) > 0
BEGIN
	SET @acc0 = CONVERT(decimal(15, 0), SUBSTRING(@template, CHARINDEX(',', @template) + 1, LEN(@template)))
	SET @template = LTRIM(RTRIM(SUBSTRING(@template, 1, CHARINDEX(',', @template) - 1)))

	IF @acc0 > @acc
		SET @acc = @acc0
END

SET @acc0 = @acc
SET @client_no = ISNULL(@client_no, 0)
SET @product_no = ISNULL(@product_no, 0)

IF @dept_no IS NULL
	SET @dept_no = @branch_id

IF dbo.dept_branch_id(@dept_no) <> @branch_id
	SET @branch_id = dbo.dept_branch_id(@dept_no)

IF @user_id IS NOT NULL
	DELETE FROM dbo.RESERVED_ACCOUNTS
	WHERE [USER_ID] = @user_id OR ACCOUNT = @acc OR DATEDIFF(mi,DT_TM,GETDATE()) > 10

DECLARE @uch char(3)

SELECT @uch = REVERSE(LEFT(REVERSE(VALS),3))
FROM dbo.INI_INT (NOLOCK)
WHERE IDS = 'OUR_BANK_CODE'

DECLARE
	@keypos tinyint,
	@branch_str varchar(20),
	@dept_str varchar(20),
	@client_str varchar(20),
	@product_str varchar(20),
	@bal_acc_str varchar(6),
	@pos int,
	@length char(1)

SET @bal_acc_str = REPLACE (@bal_acc, '.', '')
SET @bal_acc_str = REPLICATE('0', 6 - LEN(@bal_acc_str)) + @bal_acc_str

SET @template = REPLACE (@template, '{C}', CASE WHEN @iso = 'GEL' THEN '0' ELSE '1' END)

SET @pos = PATINDEX ('%{B%}%', @template)
IF @pos > 0
BEGIN 
	SET @length = SUBSTRING (@template, @pos + 2, 1)
	SET @branch_str = RIGHT(CONVERT(varchar(20), @branch_id), @length) 
	SET @template = REPLACE (@template, '{B' + @length + '}', REPLICATE('0', @length - LEN(@branch_str)) + @branch_str)
END

SET @pos = PATINDEX ('%{D%}%', @template)
IF @pos > 0
BEGIN 
	SET @length = SUBSTRING (@template, @pos + 2, 1)
	SET @dept_str = RIGHT(CONVERT(varchar(20), @dept_no), @length) 
	SET @template = REPLACE (@template, '{D' + @length + '}', REPLICATE('0', @length - LEN(@dept_str)) + @dept_str)
END

SET @pos = PATINDEX ('%{L%}%', @template)
IF @pos > 0
BEGIN
	SET @length = SUBSTRING (@template, @pos + 2, 1)
	SET @client_str = RIGHT(CONVERT(varchar(20), @client_no), @length)
	SET @template = REPLACE (@template, '{L' + @length + '}', REPLICATE('0', @length - LEN(@client_str)) + @client_str)
END

SET @pos = PATINDEX ('%{P%}%', @template)
IF @pos > 0
BEGIN
	SET @length = SUBSTRING (@template, @pos + 2, 1)
	SET @product_str = RIGHT(CONVERT(varchar(20), @product_no), @length)
	SET @template = REPLACE (@template, '{P' + @length + '}', REPLICATE('0', @length - LEN(@product_str)) + @product_str)
END

SET @pos = PATINDEX ('%{A%}%', @template)
WHILE @pos > 0
BEGIN
	SET @length = SUBSTRING (@template, @pos + 2, 1)
	SET @pos = CONVERT(int, @length)
	SET @template = REPLACE (@template, '{A' + @length + '}', SUBSTRING(@bal_acc_str, @pos, 1))

	SET @pos = PATINDEX ('%{A%}%', @template)
END

SET @keypos = CHARINDEX('K',REVERSE(@template))
IF @keypos > 0
	SET @template = REPLACE (@template, 'K', '0')

IF (LEN(@template) < 15) AND (CHARINDEX('n',@template) > 0)
  SET @template = STUFF(@template,CHARINDEX('n',@template),1,REPLICATE('N',16-len(@template)))

IF CHARINDEX('N',@template) = 0
BEGIN
  SET @acc = CONVERT(decimal(15,0), @template)
  IF @return_row <> 0
    SELECT @acc
  RETURN
END

DECLARE
	@s varchar(15),
	@tmp varchar(15),
	@b_int int

SET @s = REVERSE(@acc)
SET @tmp = REVERSE(@template)

WHILE 1=1 
BEGIN
	SET @b_int = PATINDEX('%[^Nn#]%',@tmp)
	IF @b_int > 0 
	BEGIN
		SET @tmp = STUFF(@tmp,@b_int,1,'#')
		IF LEN(@s) >= @b_int
			SET @s = STUFF(@s,@b_int,1,'#')
	END
	ELSE BREAK
END

IF REPLACE(@s,'#','') = ''
	SET @acc = '0'
ELSE SET @acc = REPLACE(REVERSE(@s),'#','')


WHILE 1=1
BEGIN
	SET @acc = @acc + 1
	SET @s = LTRIM(STR(@acc,16))
	SET @s = REVERSE(REPLICATE('0',16-len(@s)) + @s)
	SET @tmp = REVERSE(@template)

	SET @b_int = 0
	WHILE 1=1
	BEGIN
		SET @b_int = CHARINDEX('N',@tmp,@b_int+1)
		IF @b_int > 0
		BEGIN
			SET @tmp = STUFF(@tmp,@b_int,1,SUBSTRING(@s,1,1))
			SET @s = STUFF(@s,1,1,'')
		END
		ELSE BREAK
	END
	SET @s = @tmp

	SET @b_int = 1
	WHILE @b_int < len(@s)
	BEGIN
		SET @tmp = SUBSTRING(@s,@b_int,1)
		SET @s = STUFF(@s,@b_int,1,@tmp)
		SET @b_int = @b_int + 1
	END
	SET @s = REVERSE(@s)

	DECLARE
		@position int,
		@m int,
		@mstr varchar(18),
		@magic_str varchar(18)

	SET @mstr = CONVERT(DECIMAL(15,0),@s)

	IF CONVERT(DECIMAL(15,0),@s) >= 1000000000
	BEGIN
		SET @mstr = REPLICATE('0',15-len(@mstr)) + @mstr
		SET @mstr = LEFT(@mstr,6) + @uch + RIGHT(@mstr,9)
		SET @magic_str = '371371713371371371'  
	END
	ELSE
	BEGIN
		SET @mstr = @uch + REPLICATE('0',9-len(@mstr)) + @mstr 
		SET @magic_str = '713371371371'  
	END

	SET @position = 1
	SET @m = 0

	WHILE @position <= len(@magic_str)
	BEGIN
		SET @m = @m + (ASCII(SUBSTRING(@mstr, @position, 1))-ASCII('0')) * (ASCII(SUBSTRING(@magic_str, @position, 1))-ASCII('0'))
		SET @position = @position + 1
	END

	SET @m = @m % 10

	IF @m <> 0 
	BEGIN
		SET @mstr = SUBSTRING(REVERSE(@magic_str), @keypos, 1);
		IF @mstr = '1'
			SET @s = REVERSE(STUFF(REVERSE(@s),@keypos,1,CHAR(ASCII('0')+10-@m)))
		ELSE
		IF @mstr = '3'
			SET @s = REVERSE(STUFF(REVERSE(@s),@keypos,1,CHAR(ASCII('0')+(@m * 3) % 10)))
		ELSE
		IF @mstr = '7'
			SET @s = REVERSE(STUFF(REVERSE(@s),@keypos,1,CHAR(ASCII('0')+(@m * 7) % 10)))
	END

	DECLARE @s_account TACCOUNT
	SET @s_account = CONVERT(decimal(15,0), @s)

	IF EXISTS(SELECT * FROM dbo.RESERVED_ACCOUNTS WHERE ACCOUNT = @s_account) 
		CONTINUE

	IF @acc0 <> 0 
	BEGIN
		IF @new_acc_unique <> 0
		BEGIN
			IF EXISTS(SELECT * FROM dbo.ACCOUNTS (NOLOCK) WHERE ACCOUNT = @s_account)
				CONTINUE
		END
		ELSE
		BEGIN
			IF EXISTS(SELECT * FROM dbo.ACCOUNTS (NOLOCK) WHERE BRANCH_ID = @branch_id AND ACCOUNT = @s_account)
				CONTINUE
		END
	END
	ELSE
	BEGIN
		IF @new_acc_unique <> 0
		BEGIN
			IF EXISTS(SELECT * FROM dbo.ACCOUNTS (NOLOCK) WHERE ACCOUNT = @s_account)
				CONTINUE

			IF @client_no <> 0 AND EXISTS(SELECT * FROM dbo.ACCOUNTS (NOLOCK) WHERE ACCOUNT = @s_account AND CLIENT_NO <> @client_no)
				CONTINUE
		END
		ELSE
		BEGIN
			IF EXISTS(SELECT * FROM dbo.ACCOUNTS (NOLOCK) WHERE BRANCH_ID = @branch_id AND ACCOUNT = @s_account AND ISO = @iso)
				CONTINUE

			IF @client_no <> 0 AND EXISTS(SELECT * FROM dbo.ACCOUNTS (NOLOCK) WHERE BRANCH_ID = @branch_id AND ACCOUNT = @s_account AND CLIENT_NO <> @client_no)
				CONTINUE
		END
	END
	BREAK
END

IF @user_id IS NOT NULL
	INSERT INTO dbo.RESERVED_ACCOUNTS (ACCOUNT,ISO,[USER_ID]) VALUES (@s_account, @iso, @user_id)

SET @acc = @s_account

IF @return_row <> 0
  SELECT @acc
GO
