SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ON_USER_AFTER_ADD_TARIFF_DOC]
	@tariff_doc_rec_id int,
	@tariff_amount money,
	@tariff_id int,
	@tariff_doc_type smallint,
	@tariff_op_code varchar(5),
	@client_no int,
	@descrip varchar(150),
	@user_id int,
	@owner int,
	@dept_no int,
	@doc_type smallint,
	@doc_date smalldatetime,
	@debit_id int,
	@credit_id int,
	@iso char(3) ,
	@amount money,
	@amount2 money = null,
	@cash_amount money,
	@flags int,
	@op_code varchar(5),
	@doc_num int,
	@extra decimal(15,0),
	@prod_id int,
	@foreign_id int,
	@channel_id int,
	@cashier int,
	@receiver_bank_code varchar(37),
	@det_of_charg char(3),
	@rate_flags int,
	@info bit
AS

SET NOCOUNT ON;

RETURN 0;
GO
