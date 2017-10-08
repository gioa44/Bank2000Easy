SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ON_USER_AFTER_ADD_CONV_DOC]
	@rec_id_1 int OUTPUT,
	@rec_id_2 int OUTPUT,

  	@user_id int,
	@owner int,
	@iso_d TISO,
	@iso_c TISO,
	@amount_d money,
	@amount_c money,
	@debit_id int,
	@credit_id int,
	@doc_date smalldatetime,
	@op_code TOPCODE,
	@doc_num int,
	@account_extra TACCOUNT,

	@is_kassa bit,

	@descrip1 varchar(150),
	@descrip2 varchar(150),
	@rec_state tinyint,
	@bnk_cli_id int,
	@par_rec_id int,

	@dept_no int,
	@prod_id int,
	@foreign_id int,
	@channel_id int,
	@is_suspicious bit,   

	@relation_id int,
	@flags int,

	@rate_items int,
	@rate_amount money,
	@rate_reverse bit,
	@rate_flags int,
	@tariff_kind bit,
	@lat_descrip bit,

	@client_no int,
	@rate_client_no int,

	@first_name varchar(50),
	@last_name varchar(50),
	@fathers_name varchar(50),
	@birth_date smalldatetime,
	@birth_place varchar(100),
	@address_jur varchar(100),
	@address_lat varchar(100),
	@country varchar(2), 
	@passport_type_id tinyint,
	@passport varchar(50),
	@personal_id varchar(20),
	@reg_organ varchar(50),
	@passport_issue_dt smalldatetime,
	@passport_end_date smalldatetime,

	@doc_type1 smallint,
	@doc_type2 smallint,

	@check_saldo bit,
	@add_tariff bit,
	@info bit,
	@lat bit,
	@extra_params xml
AS

SET NOCOUNT ON;
GO
