SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_get_convert_amount]
	@client_no int,
	@iso1 char(3),
	@iso2 char(3),
	@amount money,
	@new_amount TAMOUNT = NULL OUTPUT,
	@show_result bit = 0
AS

SET NOCOUNT ON;

IF @iso1 = @iso2
BEGIN
	SET @new_amount = @amount
	IF @show_result = 1
		SELECT @new_amount AS NEW_AMOUNT
	RETURN (0)
END

DECLARE
	@r int, 
	@rate_politics_id int

SET @rate_politics_id = NULL

IF @client_no IS NOT NULL
BEGIN
  SELECT @rate_politics_id = RATE_POLITICS_ID
  FROM dbo.CLIENTS (NOLOCK)
  WHERE CLIENT_NO = @client_no
END

DECLARE
	@rate_amount money,
	@rate_items int,
	@reverse bit

EXEC dbo.GET_CROSS_RATE
  @rate_politics_id = @rate_politics_id,
  @iso1 = @iso1,
  @iso2	= @iso2,
  @look_buy = 1,
  @amount = @rate_amount OUTPUT,
  @items = @rate_items	OUTPUT,
  @reverse = @reverse OUTPUT,
  @rate_type = 0
  
IF @rate_amount = $0.00 OR @rate_items = 0
BEGIN
	IF @show_result = 1
		SELECT @new_amount AS NEW_AMOUNT
	RETURN (1)
END	
	
IF @reverse = 0
	SET @new_amount = @amount * @rate_amount / @rate_items
ELSE	
	SET @new_amount = @amount * @rate_items / @rate_amount


EXEC @r = ROUND_BY_ISO @new_amount,@iso2, @new_amount OUTPUT

IF @show_result = 1
	SELECT @new_amount AS NEW_AMOUNT

RETURN @r

GO
