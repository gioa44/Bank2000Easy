SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ON_USER_BEFORE_AUTHORIZE_DOC] 
	@doc_rec_id int,
	@user_id int,
		@owner int,
@new_rec_state tinyint,
	@old_rec_state tinyint
,	@parent_rec_id int,
	@dept_no int,
	@doc_type smallint,
	@doc_date smalldatetime,
	@doc_date_in_doc smalldatetime,
	@debit_id int,
	@credit_id int,
	@iso char(3),
	@amount money,
	@cash_amount money,
	@op_code varchar(5),
	@doc_num int,
	@account_extra decimal(15,0),
	@prod_id int,
	@foreign_id int,
	@channel_id int,
	@relation_id int, 
	@cashier int,
	@info bit,
	@lat bit
AS

RETURN 0
GO
