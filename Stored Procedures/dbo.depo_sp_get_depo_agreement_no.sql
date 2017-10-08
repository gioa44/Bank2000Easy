SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_get_depo_agreement_no]
	@agreement_no varchar(100) OUTPUT,
	@template varchar(255),
	@date smalldatetime,
	@client_no int,
	@dept_no int,
	@ccy char(3),
	@prod_id int
AS
SET NOCOUNT ON;

DECLARE
	@r int

SET @r = 0

IF ISNULL(@template, '') = '' GOTO ERR

DECLARE
	@prod_no int,			--> [PN] - Product No (4 digict)
	@dcd int,				--> [DCD] - Deposits Count in Day
	@dcm int,				--> [DCM] - Deposits Count in Months
	@dcy int,				--> [DCY] - Deposits Count in Year
	@dcc int,				--> [DCC] - Client Deposits Count
	@dccp int,				--> [DCCP] - Client Deposits Count For Product
	@dccd int,				--> [DCCP] - Client Deposits Count For Date
	@dc int,				--> [DC] - All Deposit Count
	@dcp int				--> [DCP] - All Deposit Count For Product

SET @prod_no = NULL
SET @dcd = NULL
SET @dcm = NULL
SET @dcy = NULL
SET @dcc = NULL
SET @dccp = NULL
SET @dccd = NULL
SET @dc = NULL
SET @dcp = NULL

IF CHARINDEX('PN', UPPER(@template)) <> 0
	SELECT @prod_no = PROD_NO FROM dbo.DEPO_PRODUCTS (NOLOCK)
	WHERE PROD_ID = @prod_id

IF CHARINDEX('DCD', UPPER(@template)) <> 0
	SELECT @dcd = COUNT(*) FROM dbo.DEPO_DEPOSITS
	WHERE [START_DATE] = @date

IF CHARINDEX('DCM', UPPER(@template)) <> 0
	SELECT @dcm = COUNT(*) FROM dbo.DEPO_DEPOSITS
	WHERE DATEPART(yyyy, [START_DATE]) = DATEPART(yyyy, @date) AND DATEPART(mm, [START_DATE]) = DATEPART(mm, @date)

IF CHARINDEX('DCY', UPPER(@template)) <> 0
	SELECT @dcy = COUNT(*) FROM dbo.DEPO_DEPOSITS
	WHERE DATEPART(yyyy, [START_DATE]) = DATEPART(yyyy, [START_DATE])

IF CHARINDEX('DCC', UPPER(@template)) <> 0
	SELECT @dcc = COUNT(*) FROM dbo.DEPO_DEPOSITS
	WHERE CLIENT_NO = @client_no

IF CHARINDEX('DCCP', UPPER(@template)) <> 0
	SELECT @dccp = COUNT(*) FROM dbo.DEPO_DEPOSITS
	WHERE PROD_ID = @prod_id AND CLIENT_NO = @client_no
	
IF CHARINDEX('DCCD', UPPER(@template)) <> 0
	SELECT @dccd = COUNT(*) FROM dbo.DEPO_DEPOSITS
	WHERE CLIENT_NO = @client_no AND [START_DATE] = @date
	
IF CHARINDEX('DC', UPPER(@template)) <> 0
	SELECT @dc = COUNT(*) FROM dbo.DEPO_DEPOSITS


IF CHARINDEX('DCP', UPPER(@template)) <> 0
	SELECT @dcp = COUNT(*) FROM dbo.DEPO_DEPOSITS
	WHERE PROD_ID = @prod_id

EXEC @r = dbo.depo_sp_generate_next_agreement_no
	@agreement_no = @agreement_no OUTPUT,
	@template = @template,
	@date = @date,
	@client_no = @client_no,
	@dept_no = @dept_no,
	@ccy = @ccy,
	@prod_no = @prod_no,
	@dcd = @dcd,
	@dcm = @dcm,
	@dcy = @dcy,
	@dcc = @dcc,
	@dccp = @dccp,
	@dccd = @dccd,
	@dc = @dc,
	@dcp = @dcp

IF @r = 0 AND @@ERROR = 0 
	RETURN 0
ERR:
	SET @agreement_no = '!!!ERROR!!!'
	RETURN @r

GO
