SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_generate_account]
	@account		TACCOUNT OUTPUT,  
	@template		varchar(150),
	@branch_id		int,
	@dept_id		int,
	@bal_acc		TBAL_ACC,  
	@depo_bal_acc	TBAL_ACC = NULL,
	@client_no		int, 
	@ccy			TISO, 
	@prod_code4		int 
AS

--	N - number
--	n - number or blank
--	{CCY}		= Currency (GEL -> 0, ELSE -> 1)
--	{An}		= Balance Account, where n = (1,2,3,4,5,6)
--	{DAn}		= Deposit Balance Account, where n = (1,2,3,4,5,6)
--	{Bn}		= Branch Number, where n = 1...9
--	{Dn}		= Dept Number, where n = 1...9	
--	{Cn}		= Client Number, where n = 1...6
--	{Pn}		= Product Number, where n = 1...3
--	{OWN_TEMPLATE} = BANK OWN TEMPLATE 

SET NOCOUNT ON;

DECLARE 
	@next bit,
	@generate bit
 
DECLARE @acc0 TACCOUNT

SET @account = ISNULL(@account, 0)

IF CHARINDEX(',', @template) > 0
BEGIN
	SET @acc0 = CONVERT(decimal(15, 0), SUBSTRING(@template, CHARINDEX(',', @template) + 1, LEN(@template)))
	SET @template = LTRIM(RTRIM(SUBSTRING(@template, 1, CHARINDEX(',', @template) - 1)))

	IF @acc0 > @account
		SET @account = @acc0
END

SET @acc0 = @account
SET @client_no = ISNULL(@client_no, 0)
SET @prod_code4 = ISNULL(@prod_code4, 0)

IF ISNULL(@template,'') = ''
BEGIN
	SET @account = NULL
	RETURN (0)
END

IF @template = '{OWN_TEMPLATE}'
BEGIN
	EXEC dbo.on_user_depo_sp_generate_account
		@account		= @account OUTPUT,  
		@template		= @template,
		@branch_id		= @branch_id,
		@dept_id		= @dept_id,
		@bal_acc		= @bal_acc,  
		@depo_bal_acc	= @depo_bal_acc,
		@client_no		= @client_no, 
		@ccy			= @ccy, 
		@prod_code4		= @prod_code4

	RETURN
END

SET @next = CASE WHEN CHARINDEX('N',UPPER(@template)) = 0 THEN 0 ELSE 1 END
SET @generate = CASE WHEN CHARINDEX('K',UPPER(@template)) = 0 THEN 0 ELSE 1 END

IF CHARINDEX('o',@template) <> 0
	SET @template = SUBSTRING(@template, 1, CHARINDEX('o', @template) - 1) +
		SUBSTRING(@template, CHARINDEX('o', @template) + 1, LEN(@template))

DECLARE
	@uch char(3)

SELECT @uch = REVERSE(LEFT(REVERSE(VALS),3))
FROM dbo.INI_INT (NOLOCK)
WHERE IDS = 'OUR_BANK_CODE'

DECLARE
	@keypos tinyint,
	@branch_str varchar(20),
	@debt_str varchar(20),
	@client_str varchar(20),
	@loan_str varchar(20),
    @prod_code4_str varchar(4),
    @bal_acc_str varchar(6),
	@depo_bal_acc_str varchar(6),
    @pos int,
    @length char(1)
    

SET @bal_acc_str = REPLACE(@bal_acc, '.', '')
SET @bal_acc_str = REPLICATE('0', 6 - LEN(@bal_acc_str)) + @bal_acc_str

SET @depo_bal_acc_str = REPLACE(@depo_bal_acc, '.', '')
SET @depo_bal_acc_str = REPLICATE('0', 6 - LEN(@depo_bal_acc_str)) + @depo_bal_acc_str

SET @template = REPLACE(@template, '{CCY}', CASE WHEN @ccy = 'GEL' THEN '0' ELSE '1' END)


SET @pos = PATINDEX ('%{B%}%', @template)
IF @pos > 0
BEGIN 
	SET @length = SUBSTRING(@template, @pos + 2, 1)
	SET @branch_str = RIGHT(CONVERT(varchar(20), @branch_id), @length) 
	SET @template = REPLACE(@template, '{B' + @length + '}', REPLICATE('0', @length - LEN(@branch_str)) + @branch_str)
	SET @pos = PATINDEX ('%{B%}%', @template)
END

SET @pos = PATINDEX ('%{C%}%', @template)
IF @pos > 0
BEGIN
	SET @length = SUBSTRING(@template, @pos + 2, 1)
	SET @client_str = RIGHT(CONVERT(varchar(20), @client_no), @length)
	SET @template = REPLACE(@template, '{C' + @length + '}', REPLICATE('0', @length - LEN(@client_str)) + @client_str)
	SET @pos = PATINDEX ('%{C%}%', @template)
END


SET @pos = PATINDEX ('%{P%}%', @template)
IF @pos > 0
BEGIN
	SET @length = SUBSTRING(@template, @pos + 2, 1)
	SET @prod_code4_str = RIGHT(CONVERT(varchar(4), @prod_code4), @length)
	SET @template = REPLACE(@template, '{P' + @length + '}', REPLICATE('0', @length - LEN(@prod_code4_str)) + @prod_code4_str)
	SET @pos = PATINDEX ('%{P%}%', @template)
END

SET @pos = PATINDEX ('%{A_}%', @template)
WHILE @pos > 0
BEGIN
	SET @length = SUBSTRING(@template, @pos + 2, 1)
	SET @pos = CONVERT(int, @length)
	SET @template = REPLACE(@template, '{A' + @length + '}', SUBSTRING(@bal_acc_str, @pos, 1))

	SET @pos = PATINDEX ('%{A_}%', @template)
END

SET @pos = PATINDEX ('%{DA_}%', @template)
WHILE @pos > 0
BEGIN
	SET @length = SUBSTRING(@template, @pos + 3, 1)
	SET @pos = CONVERT(int, @length)
	SET @template = REPLACE(@template, '{DA' + @length + '}', SUBSTRING(@depo_bal_acc_str, @pos, 1))
 
	SET @pos = PATINDEX ('%{DA_}%', @template)
END

SET @pos = PATINDEX ('%{D%}%', @template)
IF @pos > 0
BEGIN 
	SET @length = SUBSTRING(@template, @pos + 2, 1)
	SET @debt_str = RIGHT(CONVERT(varchar(20), @dept_id), @length) 
	SET @template = REPLACE(@template, '{D' + @length + '}', REPLICATE('0', @length - LEN(@debt_str)) + @debt_str)
END

SET @keypos = CHARINDEX('K',REVERSE(@template))
IF @keypos > 0
	SET @template = REPLACE (@template, 'K', '0')

IF (len(@template) < 15) and (CHARINDEX('n',@template) > 0)
  SET @template = STUFF(@template,CHARINDEX('n',@template),1,REPLICATE('N',16-len(@template)))

IF @next = 0 AND @generate = 0
BEGIN
  SET @account = CONVERT(decimal(15,0), @template)
  RETURN
END


DECLARE
	@s varchar(15),
	@tmp varchar(15),
	@b_int int

SET @s = REVERSE(@account)
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
	SET @account = '0'
ELSE SET @account = REPLACE(REVERSE(@s),'#','')

DECLARE @s_account TACCOUNT

WHILE 1=1
BEGIN
	SET @account = @account + 1
	SET @s = LTRIM(STR(@account, 16))
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

	SET @s_account = CONVERT(decimal(15,0), @s)

	IF @next = 0 BREAK

	IF EXISTS(SELECT * FROM dbo.RESERVED_ACCOUNTS WHERE ACCOUNT = @s_account) 
		CONTINUE

	IF @acc0 <> 0 
	BEGIN
		IF EXISTS(SELECT * FROM dbo.ACCOUNTS (NOLOCK) WHERE BRANCH_ID = @branch_id AND ACCOUNT = @s_account)
			CONTINUE
	END
	ELSE
	BEGIN
		IF EXISTS(SELECT * FROM dbo.ACCOUNTS (NOLOCK) WHERE BRANCH_ID = @branch_id AND ACCOUNT = @s_account AND ISO = @ccy)
			CONTINUE
			
		IF @client_no <> 0 AND EXISTS(SELECT * FROM dbo.ACCOUNTS (NOLOCK) WHERE BRANCH_ID = @branch_id AND ACCOUNT = @s_account AND CLIENT_NO <> @client_no)
			CONTINUE
	END
	BREAK
END

SET @account = @s_account

RETURN 0
GO
