SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  PROCEDURE [dbo].[ON_CHECK_SALDO_EXTRA]
  @account TACCOUNT,
  @iso TISO,
  @is_credit bit,
  @actpas tinyint,
  @lat bit = 0,
  @rec_id int = 0,
  @saldo TAMOUNT = $0.00,
  @delta TAMOUNT = $0.00,
  @min TAMOUNT = $0.00,
  @block TAMOUNT = $0.00,
  @delta_2 TAMOUNT  OUTPUT
AS

  SET @delta_2=0
  RETURN(0)

GO
