SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_get_cred_perc_schema_data]
	@acc_id int
AS
SET NOCOUNT ON;

SELECT *
FROM dbo.ACCOUNTS_CRED_PERC (NOLOCK)
WHERE ACC_ID = @acc_id

RETURN 0

GO