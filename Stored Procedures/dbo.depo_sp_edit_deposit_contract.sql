SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_edit_deposit_contract]
	@depo_id int,
	@user_id int,
	@branch_id int,
	@dept_no int,
	@client_no int,
	@trust_deposit bit = NULL,
	@trust_client_no int = NULL,
	@trust_extra_info varchar(255) = NULL,
	@prod_id int,
	@iso TISO,
	@agreement_amount money = NULL,
	@period int = NULL,
	@start_date smalldatetime,
	@end_date smalldatetime = NULL,
	@intrate money,

	@depo_realize_schema_amount money = NULL, 

	@convertible bit, 
	@prolongable bit,

	@shareable bit,
	@shared_control_client_no int = NULL,
	@shared_control bit,

	@child_control_client_no_1 int = NULL,
	@child_control_client_no_2 int = NULL,

	@depo_fill_acc_id int = NULL,
	@depo_realize_acc_id int = NULL,
	@interest_realize_type tinyint,
	@interest_realize_acc_id int = NULL,

	@interest_realize_adv bit,
	@interest_realize_adv_amount money = NULL,

	@accumulative bit,
	@accumulate_product bit,
	@accumulate_amount money = NULL,

	@renewable bit,
	@renew_capitalized bit,
	@renew_max int = NULL,

	@spend bit,
	@spend_intrate money = NULL,
	@spend_amount money  = NULL,

	@depo_acc_id int = NULL, --ანაბრის ანგარიში
	@loss_acc_id int = NULL, --ხარჯის ანგარიში
	@accrual_acc_id int = NULL, --დაგროვების ანგარიში
	@interest_realize_adv_acc_id int = NULL, --სატრანზიტო ანგარიში სარგებლის წინასწარი რეალიზაციის დროს
	@depo_note varchar(255) = NULL
AS

SET NOCOUNT ON;

DECLARE
	@r int

EXEC @r = dbo.depo_sp_add_deposit_contract
	@depo_id = @depo_id OUTPUT,
	@user_id = @user_id,
	@branch_id = @branch_id,
	@dept_no = @dept_no,
	@client_no = @client_no,
	@trust_deposit = @trust_deposit,
	@trust_client_no = @trust_client_no,
	@trust_extra_info = @trust_extra_info,
	@prod_id = @prod_id,
	@iso = @iso,
	@agreement_amount = @agreement_amount,
	@period = @period,
	@start_date = @start_date,
	@end_date = @end_date,
	@intrate = @intrate,
	@depo_realize_schema_amount = @depo_realize_schema_amount, 
	@convertible = @convertible, 
	@prolongable = @prolongable,
	@shareable = @shareable,
	@shared_control_client_no = @shared_control_client_no,
	@shared_control = @shared_control,
	@child_control_client_no_1 = @child_control_client_no_1,
	@child_control_client_no_2 = @child_control_client_no_2,
	@depo_fill_acc_id = @depo_fill_acc_id,
	@depo_realize_acc_id = @depo_realize_acc_id,
	@interest_realize_type = @interest_realize_type,
	@interest_realize_acc_id = @interest_realize_acc_id,
	@interest_realize_adv = @interest_realize_adv,
	@interest_realize_adv_amount = @interest_realize_adv_amount,
	@accumulative = @accumulative,
	@accumulate_product = @accumulate_product,
	@accumulate_amount = @accumulate_amount,
	@renewable = @renewable,
	@renew_capitalized = @renew_capitalized,
	@renew_max = @renew_max,
	@spend = @spend,
	@spend_intrate = @spend_intrate,
	@spend_amount = @spend_amount,
	@depo_acc_id = @depo_acc_id,
	@loss_acc_id = @loss_acc_id,
	@accrual_acc_id = @accrual_acc_id,
	@interest_realize_adv_acc_id = @interest_realize_adv_acc_id,
	@depo_note = @depo_note,
	@editing = 1
IF @@ERROR <> 0 OR @r <> 0 BEGIN RAISERROR ('ERROR EDITING DEPOSIT', 16, 1) RETURN (1) END

RETURN 0

GO
