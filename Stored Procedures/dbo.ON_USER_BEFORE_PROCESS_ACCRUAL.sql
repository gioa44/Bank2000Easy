SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ON_USER_BEFORE_PROCESS_ACCRUAL] 
	@perc_type tinyint,
	@acc_id int,
	@user_id int,
	@dept_no int,
	@doc_date smalldatetime,
	@calc_date smalldatetime,
	@force_calc bit = 0,
	@force_realization bit = 0,
	@simulate bit = 0,
	@recalc_option tinyint = 0 OUTPUT,
								-- 0x00 - Calc as usual
								-- 0x01 - Recalc from beginning
								-- 0x02 - Recalc from last realiz. date
	@formula varchar(512) OUTPUT 
AS

SET NOCOUNT ON;

GO
