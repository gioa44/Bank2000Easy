SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[depo_sp_mark_default_on_user]
	@depo_id int,
	@analyze_date smalldatetime,
	@user_id int
AS
SET NOCOUNT ON;

RETURN 0
GO
