SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[on_user_before_import_docs_out_nbg]
	@rec_id int, 
	@is_close_day bit = 0, 
	@portion_date smalldatetime, 
	@portion int, 
	@doc_num int OUTPUT,
	@doc_date smalldatetime OUTPUT, 
	@doc_date_in_doc smalldatetime OUTPUT, 
	@rec_date smalldatetime OUTPUT, 
	@amount money, 
	@descrip varchar(150) OUTPUT,
	@sender_bank_code int OUTPUT, 
	@sender_bank_name varchar(50) OUTPUT,
	@sender_acc varchar(37) OUTPUT, 
	@sender_acc_name varchar(100) OUTPUT,
	@sender_tax_code varchar(11) OUTPUT,
	@receiver_bank_code int OUTPUT, 
	@receiver_bank_name varchar(50) OUTPUT,
	@receiver_acc varchar(37) OUTPUT, 
	@receiver_acc_name varchar(100) OUTPUT,
	@receiver_tax_code varchar(11) OUTPUT,
	@extra_info varchar(250) OUTPUT,
	@saxazkod varchar(11) OUTPUT,
	@op_code TOPCODE,
	@account_extra TACCOUNT,
	@skip bit OUTPUT
AS
BEGIN
	SET @skip = 0
	SET @sender_bank_code = dbo.get_real_bank_code(@sender_bank_code)
	RETURN 0
END
GO
