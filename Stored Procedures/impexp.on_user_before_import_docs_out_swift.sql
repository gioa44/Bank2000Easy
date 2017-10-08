SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[on_user_before_import_docs_out_swift] 
	@rec_id int,
	@is_close_day bit = 0, 
	@portion_date smalldatetime,
	@portion int OUTPUT,
	@doc_num int,
	@doc_date smalldatetime,
	@iso char(3),
	@amount money,
	@amount_equ money,
	@doc_credit_id int OUTPUT,
	@ref_num varchar(32) OUTPUT,
	@descrip varchar(150) OUTPUT,
    @sender_bank_code varchar(37) OUTPUT,
	@sender_bank_name varchar(105) OUTPUT,
	@sender_acc varchar(37) OUTPUT,
	@sender_acc_name varchar(105) OUTPUT,
	@sender_address_lat varchar(105) OUTPUT,
	@receiver_bank_code varchar(37) OUTPUT,
	@receiver_bank_name varchar(105) OUTPUT,
	@receiver_acc varchar(37) OUTPUT,
	@receiver_acc_name varchar(105) OUTPUT,
	@intermed_bank_code varchar(37) OUTPUT,
	@intermed_bank_name varchar(105) OUTPUT,
	@intermed_bank_code2 varchar(37) OUTPUT,
	@intermed_bank_name2 varchar(105) OUTPUT,
	@cor_bank_code varchar(37),
	@cor_bank_name varchar(105),
	@correspondent_bank_id int OUTPUT,
	@extra_info varchar(255) OUTPUT,
	@extra_info_descrip bit OUTPUT,
	@det_of_charg char(3) OUTPUT,
	@swift_flags_1 int OUTPUT,
	@swift_flags_2 int OUTPUT,
	@op_code TOPCODE,
	@account_extra TACCOUNT,
	@skip bit OUTPUT
AS
BEGIN
	SET @skip = 0
	RETURN 0
END
GO
