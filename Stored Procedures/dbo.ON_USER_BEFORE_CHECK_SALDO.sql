SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ON_USER_BEFORE_CHECK_SALDO] 
	@effective_saldo money OUTPUT, 
	@acc_id int, 
	@doc_date smalldatetime, 
	@op_code TOPCODE, 
	@doc_type smallint,
	@doc_rec_id int,
	@lat bit
AS

SET @effective_saldo = NULL
GO
