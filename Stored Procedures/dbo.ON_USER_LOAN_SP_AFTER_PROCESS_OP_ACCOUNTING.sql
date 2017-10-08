SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ON_USER_LOAN_SP_AFTER_PROCESS_OP_ACCOUNTING]
	@op_id int,
	@user_id int,
	@doc_date smalldatetime,
	@by_processing bit,
	@simulate bit
AS
SET NOCOUNT ON;

RETURN 0;
GO
