SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ON_USER_BEFORE_DELETE_DOC]
	@rec_id int,				-- საბუთის შიდა №
	@uid int,					-- საბუთის ბოლოს ცვლილების ნომერი. თუ ნულია, აღარ ვუყურებთ
	@user_id int OUTPUT,		-- ვინ შლის საბუთს

		@owner int,
	@parent_rec_id int,
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
@check_saldo bit OUTPUT,	-- შეამოწმოს თუ არა მინ. ნაშთი
	@info bit,					-- რეალურად გატარდეს OUTPUT, თუ მხოლოდ ინფორმაციაა
	@lat bit,					-- გამოიტანოს თუ არა შეცდომები ინგლისურად
	
	@extra_params xml OUTPUT	-- დამატებითი პარამეტრები, რომელიც გადაეცემა ON_USER_AFTER_DELETE_DOC პროცედურას
AS

SET NOCOUNT ON;

RETURN 0
GO
