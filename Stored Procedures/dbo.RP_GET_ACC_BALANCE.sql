SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[RP_GET_ACC_BALANCE]
 @account TACCOUNT,
 @iso TISO,
 @dt smalldatetime,
 @equ bit = 0
AS

DECLARE @rest TAMOUNT,
		@rest_equ TAMOUNT,
		@act_pas tinyint,
		@descrip_geo varchar(100),
		@descrip_lat varchar(100),
		@last_op_date smalldatetime,
		@with_info bit,
		@shadow_level smallint

 EXEC [dbo].[GET_ACC_SALDO] 
	   @account = @account
	  ,@iso = @iso
	  ,@dt = @dt
	  ,@rest = @rest OUTPUT
	  ,@rest_equ = @rest_equ OUTPUT
	  ,@act_pas = @act_pas OUTPUT
	  ,@descrip_geo = @descrip_geo OUTPUT
	  ,@descrip_lat = @descrip_lat OUTPUT
	  ,@last_op_date = @last_op_date OUTPUT
	  ,@with_info = 0
	  ,@shadow_level = 0

 SELECT CASE WHEN @equ = 0 THEN @rest ELSE @rest_equ END AS BALANCE

 RETURN (0)
GO
