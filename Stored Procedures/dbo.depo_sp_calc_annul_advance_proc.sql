SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_calc_annul_advance_proc]
	@depo_id int,
	@user_id int,
	@dept_no int,
	@annul_date smalldatetime,
	@start_point tinyint OUTPUT,
	@annul_intrate money OUTPUT,
	@annul_amount money OUTPUT
AS
SET NOCOUNT ON;

SET @start_point = 1
SET @annul_intrate = $1.00
SET @annul_amount = NULL

RETURN 0
GO
