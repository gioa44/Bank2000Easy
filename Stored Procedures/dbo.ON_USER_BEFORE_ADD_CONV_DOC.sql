SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ON_USER_BEFORE_ADD_CONV_DOC]
	@user_id int OUTPUT,
	@owner int OUTPUT,
	@iso_d TISO OUTPUT,
	@iso_c TISO OUTPUT,
	@amount_d money OUTPUT,
	@amount_c money OUTPUT,
	@debit_id int OUTPUT,
	@credit_id int OUTPUT,
	@doc_date smalldatetime OUTPUT,
	@op_code TOPCODE OUTPUT,
	@doc_num int OUTPUT,
	@account_extra TACCOUNT OUTPUT,

	@is_kassa bit OUTPUT,

	@descrip1 varchar(150) OUTPUT,
	@descrip2 varchar(150) OUTPUT,
	@rec_state tinyint OUTPUT,
	@bnk_cli_id int OUTPUT,
	@par_rec_id int OUTPUT,

	@dept_no int OUTPUT,
	@prod_id int OUTPUT,
	@foreign_id int OUTPUT,
	@channel_id int OUTPUT,
	@is_suspicious bit OUTPUT,

	@relation_id int OUTPUT,
	@flags int OUTPUT,

	@rate_items int OUTPUT,
	@rate_amount money OUTPUT,
	@rate_reverse bit OUTPUT,
	@rate_flags int OUTPUT,
	@tariff_kind bit OUTPUT,
	@lat_descrip bit OUTPUT,

	@client_no int OUTPUT,
	@rate_client_no int OUTPUT,

	@first_name varchar(50) OUTPUT,
	@last_name varchar(50) OUTPUT,
	@fathers_name varchar(50) OUTPUT,
	@birth_date smalldatetime OUTPUT,
	@birth_place varchar(100) OUTPUT,
	@address_jur varchar(100) OUTPUT,
	@address_lat varchar(100) OUTPUT,
	@country varchar(2) OUTPUT,
	@passport_type_id tinyint OUTPUT,
	@passport varchar(50) OUTPUT,
	@personal_id varchar(20) OUTPUT,
	@reg_organ varchar(50) OUTPUT,
	@passport_issue_dt smalldatetime OUTPUT,
	@passport_end_date smalldatetime OUTPUT,

	@doc_type1 smallint OUTPUT,
	@doc_type2 smallint OUTPUT,

	@check_saldo bit OUTPUT,
	@add_tariff bit OUTPUT,
	@info bit,
	@lat bit,
	@extra_params xml OUTPUT
AS

SET NOCOUNT ON;
GO
