SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ON_USER_AFTER_ADD_UTILITY_PAYMENT]
	@rec_id int,
	@user_id int, 

	@is_online bit = 1,
	@provider_id int = 0,
	@service_alias varchar(20),
	@id_in_provider varchar(50) = '',
	@id2_in_provider varchar(50) = '',
	@card_id varchar(19) = null,
	@card_type smallint = null,
	@channel_id smallint = 0,
	@full_amount money,
	@tariff_amount money = $0.0,
	@owner int = NULL,
	@dept_no int = null
AS

RETURN 0
GO
