SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_get_depo_realize_adv_bal_acc]
	@bal_acc TBAL_ACC OUTPUT,
	@depo_bal_acc TBAL_ACC,
	@client_no int,
	@prod_id int,
	@iso TISO,
	@depo_type tinyint
AS
SET NOCOUNT ON;

SET @bal_acc = CASE WHEN @iso = 'GEL' THEN 2503 ELSE 2513 END 

RETURN 0

GO
