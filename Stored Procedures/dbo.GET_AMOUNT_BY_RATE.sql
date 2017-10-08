SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[GET_AMOUNT_BY_RATE]
  @iso TISO,
  @dt smalldatetime,
  @amount money,
  @new_amount money OUTPUT
AS

SET NOCOUNT ON

SET @new_amount = ROUND( dbo.get_equ (@amount, @iso, @dt), 2)
GO
