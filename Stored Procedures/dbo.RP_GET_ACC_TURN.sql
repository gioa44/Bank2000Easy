SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
		
CREATE PROCEDURE [dbo].[RP_GET_ACC_TURN]
 @account TACCOUNT,
 @iso TISO,
 @start_date smalldatetime,
 @end_date smalldatetime,
 @equ bit = 0
AS

DECLARE @rest TAMOUNT,
		@rest_equ TAMOUNT,
		@saldo_start TAMOUNT,
		@dbo TAMOUNT,
		@cro TAMOUNT,
		@saldo_end TAMOUNT,
		@act_pas tinyint,
		@descrip_geo varchar(100),
		@descrip_lat varchar(100),
		@last_op_date smalldatetime,
		@with_info bit,
		@shadow_level smallint

 EXEC [dbo].[GET_ACC_OBOROT] 
	   @account = @account
	  ,@iso = @iso
	  ,@start_date = @start_date
	  ,@end_date =@end_date
	  ,@equ = @equ
	  ,@saldo_start = @saldo_start OUTPUT
	  ,@dbo = @dbo OUTPUT
	  ,@cro = @cro OUTPUT
	  ,@saldo_end = @saldo_end OUTPUT
	  ,@act_pas = @act_pas OUTPUT
	  ,@descrip_geo = @descrip_geo OUTPUT
	  ,@descrip_lat = @descrip_lat OUTPUT
	  ,@with_info = 0
	  ,@shadow_level = 0

 SELECT @dbo AS DEBIT, @cro AS CREDIT

 RETURN (0)
GO
