SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[DX_SPX_GET_DEPOSIT_DISB_ACCOUNT]
  @prod_id int,
  @branch_id int,
  @dept_no int,
  @product_no int,  
  @client_no int, 
  @iso TISO,
  @user_id int,
  @template varchar(100),
  @account TACCOUNT OUTPUT,
  @bal_acc TBAL_ACC OUTPUT

AS
  SET NOCOUNT ON

  DECLARE
    @r int
  DECLARE
    @opt_dx_disb_sub int

  EXEC @r = dbo.GET_SETTING_INT 'OPT_DX_DISB_SUB', @opt_dx_disb_sub OUTPUT

  SET @bal_acc = 8300 + (ISNULL(@opt_dx_disb_sub,0) / 100.00)
  
  SET @bal_acc = @bal_acc + CASE WHEN @iso = 'GEL' THEN 50 ELSE 60 END 
  
  DECLARE
    @is_juridical bit

  SELECT @is_juridical = IS_JURIDICAL
  FROM dbo.CLIENTS
  WHERE CLIENT_NO = @client_no

  SET @bal_acc = @bal_acc + CASE WHEN @is_juridical = 1 THEN 2 ELSE 1 END 

  EXEC dbo.GET_NEXT_ACC_NUM_NEW 
    @bal_acc=@bal_acc, 
    @branch_id=@branch_id, 
	@dept_no=@dept_no, 
    @client_no=@client_no, 
    @iso=@iso, 
    @product_no=@product_no, 
    @template=@template,
    @acc=@account OUTPUT,
    @user_id=@user_id,
    @return_row=0

  RETURN @@ERROR
GO
