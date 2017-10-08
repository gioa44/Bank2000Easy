SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_check_depo_renew_on_user]
	@depo_id int,
	@date smalldatetime,
	@user_id int,
	@renew bit OUTPUT
AS
SET NOCOUNT ON;

SET @renew = 1

RETURN 0

GO
