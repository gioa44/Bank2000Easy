SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[DX_SPX_GET_DEPOSIT_PERC_ACCOUNT]
  @prod_id int,
  @branch_id int,
  @dept_no int,
  @product_no int,  
  @client_no int, 
  @iso TISO,
  @user_id int,
  @template varchar(100),
  @client_account int,
  @account TACCOUNT OUTPUT,
  @bal_acc TBAL_ACC OUTPUT

AS
  SET NOCOUNT ON

  DECLARE
    @r int
  DECLARE
    @opt_dx_acrual_sub int

  EXEC @r = dbo.GET_SETTING_INT 'OPT_DX_ACRUAL_SUB', @opt_dx_acrual_sub OUTPUT
  
  IF @client_account IS NOT NULL
	SELECT @bal_acc = convert(int, BAL_ACC_ALT) FROM dbo.ACCOUNTS(NOLOCK) WHERE ACC_ID = @client_account
  ELSE
	SET @bal_acc = CASE WHEN @iso = 'GEL' THEN 3601 ELSE 3611 END

  IF @bal_acc BETWEEN 3601.00 AND 3699.99
    SET @bal_acc = CASE WHEN @iso = 'GEL' THEN 4405 ELSE 4415 END
  ELSE
  IF @bal_acc BETWEEN 3301.00 AND 3313.99
    SET @bal_acc = CASE WHEN @iso = 'GEL' THEN 4401 ELSE 4411 END
  ELSE
  IF @bal_acc BETWEEN 3401.00 AND 3418.99
    SET @bal_acc = CASE WHEN @iso = 'GEL' THEN 4402 ELSE 4412 END
  ELSE
  IF @bal_acc BETWEEN 3501.00 AND 3513.99
    SET @bal_acc = CASE WHEN @iso = 'GEL' THEN 4402 ELSE 4412 END


  SET @bal_acc = @bal_acc + (ISNULL(@opt_dx_acrual_sub,0) / 100.00)

  EXEC dbo.GET_NEXT_ACC_NUM_NEW 
    @bal_acc=@bal_acc, 
    @branch_id=@branch_id,
	@dept_no = @dept_no, 
    @client_no=@client_no, 
    @iso=@iso, 
    @product_no=@product_no, 
    @template=@template,
    @acc=@account OUTPUT,
    @user_id=@user_id,
    @return_row=0

  RETURN(0)
GO
