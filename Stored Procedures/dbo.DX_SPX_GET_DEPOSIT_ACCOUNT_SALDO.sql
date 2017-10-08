SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[DX_SPX_GET_DEPOSIT_ACCOUNT_SALDO]
  @did int,
  @dt smalldatetime
AS
  SET NOCOUNT ON
  DECLARE
    @rc int
  DECLARE
    @account TACCOUNT,
    @iso TISO,  
    @amount TAMOUNT,
    @amount_equ TAMOUNT,
    @act_pas tinyint,
    @descrip_geo varchar(100),
    @descrip_lat varchar(100),
    @last_op_date smalldatetime

  SELECT @account=ACCOUNT, @iso=ISO FROM dbo.DX_DEPOSITS WHERE DID=@did
  EXEC @rc=dbo.GET_ACC_SALDO @account=@account, @iso=@iso, @dt=@dt,
    @rest=@amount OUTPUT, @rest_equ=@amount_equ OUTPUT, @act_pas=@act_pas OUTPUT,
    @descrip_geo=@descrip_geo OUTPUT, @descrip_lat=@descrip_lat OUTPUT, @last_op_date=@last_op_date OUTPUT,
    @with_info=1, @shadow_level=0
  IF @@ERROR<>0 OR @rc<>0 BEGIN SELECT NULL AS SALDO RETURN(1) END

  IF @act_pas = 1
    SET @amount=-@amount
  
  SELECT @amount AS SALDO



GO
