SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [impexp].[on_user_before_generate_transfer_in_nbg]
	@doc_type smallint OUTPUT,
	@doc_date smalldatetime OUTPUT,
	@doc_date_in_doc smalldatetime OUTPUT,
	@debit_id int OUTPUT,
	@credit_id int OUTPUT,
	@amount money OUTPUT,
	@rec_state tinyint OUTPUT,
	@descrip varchar(150) OUTPUT,
	@op_code varchar(5) OUTPUT,
	@flags int OUTPUT,
	@doc_num int OUTPUT,
	@dept_no int OUTPUT,
  
	@sender_bank_code varchar(37) OUTPUT,
	@sender_bank_name varchar(100) OUTPUT,
	@sender_acc varchar(37) OUTPUT,
	@sender_acc_name varchar(100) OUTPUT,
	@sender_tax_code varchar(11) OUTPUT,

	@receiver_bank_code varchar(37) OUTPUT,
	@receiver_bank_name varchar(100) OUTPUT,
	@receiver_acc varchar(37) OUTPUT,
	@receiver_acc_name varchar(100) OUTPUT,
	@receiver_tax_code varchar(11) OUTPUT,

	@ref_num varchar(32) OUTPUT,
	@extra_info varchar(100) OUTPUT,
	@rec_date smalldatetime OUTPUT,
	@saxazkod varchar(100) OUTPUT,
	@account_extra TACCOUNT OUTPUT
AS

SET NOCOUNT ON;
GO
