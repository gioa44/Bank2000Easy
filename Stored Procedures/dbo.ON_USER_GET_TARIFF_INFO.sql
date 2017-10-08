SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ON_USER_GET_TARIFF_INFO]
	@result money OUTPUT,		-- აბრუნებს ტარიფის თანხას
	@tariff_id int,
	@op_type smallint,
	@tariff_doc_type smallint OUTPUT,
	@tariff_op_code varchar(5) OUTPUT,
	@client_no int,
@descrip varchar(150) OUTPUT,
	@user_id int,
	@owner int,
	@dept_no int,
	@doc_type smallint,
	@doc_date smalldatetime,
	@debit_id int OUTPUT,
	@credit_id int OUTPUT,
	@iso char(3) OUTPUT,
	@amount money,
	@amount2 money = null,
@cash_amount money,
	@flags int OUTPUT,
	@op_code varchar(5),
	@doc_num int,
	@extra decimal(15,0),
	@prod_id int OUTPUT,
	@foreign_id int OUTPUT,
	@channel_id int,
	@cashier int,
	@receiver_bank_code varchar(37),
	@det_of_charg char(3),
	@rate_flags int,
	@info bit
AS

SET NOCOUNT ON;

SET @result = NULL

RETURN 0
GO
