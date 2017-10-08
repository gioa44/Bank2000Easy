SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[on_user_depo_sp_get_depo_bal_acc]
	@bal_acc TBAL_ACC OUTPUT,
	@client_no int,
	@prod_id int,
	@iso TISO,
	@depo_type tinyint
AS
SET NOCOUNT ON;

RETURN 0
GO
