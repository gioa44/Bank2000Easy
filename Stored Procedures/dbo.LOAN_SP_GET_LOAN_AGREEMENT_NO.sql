SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_GET_LOAN_AGREEMENT_NO]
	@agr_no varchar(100) OUTPUT,
	@template varchar(255),
	@date smalldatetime,
	@product_id int,
	@client_no int,
	@dept_no int,
	@ccy char(3),
	@return_row bit = 1
AS
DECLARE
	@r int
DECLARE
	@lcd int, 
	@lcm int,
	@lcy int,
	@lcc int,
	@lccp int,
	@lc int,
	@gc int

IF CHARINDEX('LC', UPPER(@template)) <> 0
BEGIN
	UPDATE dbo.DOC_NUMBERING
	SET @lc = LAST_USED_NUM = LAST_USED_NUM + 1
	WHERE DOC_NUM_TYPE = 170
END

IF CHARINDEX('GC', UPPER(@template)) <> 0
BEGIN
	UPDATE dbo.DOC_NUMBERING
	SET @gc = LAST_USED_NUM = LAST_USED_NUM + 1
	WHERE DOC_NUM_TYPE = 171
END

IF CHARINDEX('LCD', UPPER(@template)) <> 0
BEGIN
	SELECT @lcd = COUNT(*) FROM dbo.LOANS
	WHERE REG_DATE = @date
END

IF CHARINDEX('LCM', UPPER(@template)) <> 0
BEGIN
	SELECT @lcm = COUNT(*) FROM dbo.LOANS
	WHERE DATEPART(yyyy, REG_DATE) = DATEPART(yyyy, @date) AND DATEPART(mm, REG_DATE) = DATEPART(mm, @date)
END

IF CHARINDEX('LCY', UPPER(@template)) <> 0
BEGIN
	SELECT @lcy = COUNT(*) FROM dbo.LOANS
	WHERE DATEPART(yyyy, REG_DATE) = DATEPART(yyyy, @date)
END

IF CHARINDEX('LCC', UPPER(@template)) <> 0
BEGIN
	SELECT @lcc = COUNT(*) FROM dbo.LOANS
	WHERE CLIENT_NO = @client_no
END

IF CHARINDEX('LCCP', UPPER(@template)) <> 0
BEGIN
	SELECT @lcc = COUNT(*) FROM dbo.LOANS
	WHERE CLIENT_NO = @client_no AND PRODUCT_ID = @product_id
END

EXEC @r = dbo.LOAN_SP_GENERATE_NEXT_AGREEMENT_NO
	@agr_no = @agr_no OUTPUT,
	@template = @template,
	@date = @date,
	@client_no = @client_no,
	@dept_no = @dept_no,
	@ccy = @ccy,
	@lcd = @lcd,
	@lcm = @lcm,
	@lcy = @lcy,
	@lcc = @lcc,
	@lccp = @lccp,
	@lc = @lc,
	@gc = @gc

IF @return_row = 1
	SELECT @agr_no AS AGR_NO
RETURN @r
GO
