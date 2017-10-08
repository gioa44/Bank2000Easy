SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_check_deposit_contract]
	@depo_id int,
	@user_id int
AS

SET NOCOUNT ON;

DECLARE
	@r int

RETURN 0

GO
