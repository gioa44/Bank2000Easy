SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[on_user_depo_sp_add_deposit_loss_account]
	@prod_id int,
	@client_no int,
	@descrip varchar(150) OUTPUT,
	@descrip_lat varchar(150) OUTPUT,
	@date_open smalldatetime OUTPUT,
	@period smalldatetime OUTPUT,
	@product_no int OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	RETURN 0
END

GO
