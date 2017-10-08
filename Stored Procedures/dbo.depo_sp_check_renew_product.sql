SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_check_renew_product]
	@depo_id int,
	@new_prod_id int = NULL,
	@can_renew bit OUTPUT,
	@msg varchar(200) OUTPUT
AS
BEGIN	
	SET NOCOUNT ON;	

	SET @can_renew = 1
	SET @msg = NULL
	
	DECLARE
		@depo_prod_id int,
		@depo_iso varchar(3),
		@depo_date_type int,
		@depo_amount money,
		@depo_period int,
		@depo_is_insider bit,
		@depo_is_resident bit,
		@depo_is_employee bit,
		@depo_client_type tinyint,
		@depo_client_property tinyint,
		@depo_shareable bit,
		@depo_child_deposit bit,

		@new_prod_depo_type int,
		@new_prod_date_type int,
		@new_prod_min_period int,
		@new_prod_max_period int,
		@new_prod_min_amount money,
		@new_prod_max_amount money,
		@new_prod_shareable int,
		@new_prod_child_deposit bit,
		@new_prod_interest_adv_realize int,
		@new_prod_client_type tinyint,
		@new_prod_client_property tinyint

	SELECT @depo_iso = D.ISO, @depo_prod_id = PROD_ID, @depo_amount = D.AMOUNT, @depo_date_type = D.DATE_TYPE, @depo_period = D.PERIOD,
		@depo_client_type = C.CLIENT_TYPE, @depo_is_insider  = C.IS_INSIDER, @depo_is_resident = IS_RESIDENT, @depo_is_employee = IS_EMPLOYEE,
		@depo_shareable = SHAREABLE, @depo_child_deposit = CHILD_DEPOSIT
	FROM dbo.DEPO_DEPOSITS D (NOLOCK)
		INNER JOIN dbo.CLIENTS C (NOLOCK) ON C.CLIENT_NO = D.CLIENT_NO
	WHERE DEPO_ID = @depo_id
	
	SET @new_prod_id = CASE WHEN @new_prod_id IS NULL THEN @depo_prod_id ELSE @new_prod_id END

	SET @depo_client_type = POWER(2, @depo_client_type - 1)
	SET @depo_client_property = 0

	IF @depo_is_insider = 1
		SET @depo_client_property = @depo_client_property | 1
	ELSE
		SET @depo_client_property = @depo_client_property | 2

	IF @depo_is_resident = 1
		SET @depo_client_property = @depo_client_property | 4
	ELSE
		SET @depo_client_property = @depo_client_property | 8

	IF @depo_is_employee = 1
		SET @depo_client_property = @depo_client_property | 16
	ELSE
		SET @depo_client_property = @depo_client_property | 32
	

	SELECT @new_prod_depo_type = DEPO_TYPE,  @new_prod_date_type = DATE_TYPE, 
			@new_prod_min_period = MIN_PERIOD, @new_prod_max_period = MAX_PERIOD,
			@new_prod_interest_adv_realize = INTEREST_ADV_REALIZE,
			@new_prod_shareable = SHAREABLE, @new_prod_child_deposit = CHILD_DEPOSIT,
			@new_prod_client_type = CLIENT_TYPES, @new_prod_client_property = CLIENT_PROPERTIES
	FROM dbo.DEPO_PRODUCT (NOLOCK)
	WHERE PROD_ID = @new_prod_id
	
	IF (@depo_date_type <> @new_prod_date_type)
	BEGIN
		SET @can_renew = 0
		SET @msg = 'ÀÍÀÁÒÉÓ ÃÀ ÂÀÍÀáËÄÁÉÓ ÐÒÏÃÖØÔÉÓ ÈÀÒÉÙÉÓ ÔÉÐÄÁÉ ÂÀÍÓáÅÀÅÄÁÖËÉÀ'
		RETURN 0
	END
	
	IF @depo_client_type & @new_prod_client_type = 0
	BEGIN
		SET @can_renew = 0
		SET @msg = 'ÀÒ ÄÌÈáÅÄÅÀ ÀÍÀÁÒÉÓ ÃÀ ÂÀÍÀáËÄÁÉÓ ÐÒÏÃÖØÔÉÓ ÊËÉÄÍÔÉÓ ÔÉÐÄÁÉ'
		RETURN 0
	END

	IF @depo_client_property & @new_prod_client_property = 0
	BEGIN
		SET @can_renew = 0
		SET @msg = 'ÀÒ ÄÌÈáÅÄÅÀ ÀÍÀÁÒÉÓ ÃÀ ÂÀÍÀáËÄÁÉÓ ÐÒÏÃÖØÔÉÓ ÊËÉÄÍÔÉÓ ÌÀáÀÓÉÀÈÄÁËÄÁÉ'
		RETURN 0
	END
	
	IF @depo_child_deposit = 1 AND @new_prod_child_deposit = 0
	BEGIN
		SET @can_renew = 0
		SET @msg = 'ÂÀÍÀáËÄÁÉÓ ÐÒÏÃÖØÔÉ ÖÍÃÀ ÉÚÏÓ ÓÀÁÀÅÛÅÏ'
		RETURN 0
	END
	
	IF @depo_child_deposit = 0 AND @new_prod_child_deposit = 1
	BEGIN
		SET @can_renew = 0
		SET @msg = 'ÂÀÍÀáËÄÁÉÓ ÐÒÏÃÖØÔÉ ÀÒ ÖÍÃÀ ÉÚÏÓ ÓÀÁÀÅÛÅÏ'
		RETURN 0
	END

	
	IF (@depo_period < ISNULL(@new_prod_min_period, 0)) OR ((@new_prod_max_period IS NOT NULL) AND (@depo_period > @new_prod_max_period))
	BEGIN
		SET @can_renew = 0
		SET @msg = 'ÀÍÀÁÒÉÓ ÐÄÒÉÏÃÉ ÀÒ ÛÄÓÀÁÀÌÄÁÀ ÂÀÍÀáËÄÁÉÓ ÐÒÏÃÖØÔÉÓ ÅÀÃÉÀÍÏÁÀÓ'
		RETURN 0
	END
	
	IF NOT EXISTS(
		SELECT * FROM dbo.DEPO_PRODUCT DP (NOLOCK)
			INNER JOIN dbo.DEPO_PRODUCT_PROPERTIES DPP (NOLOCK) ON DP.PROD_ID = DPP.PROD_ID
		WHERE DP.PROD_ID = @new_prod_id AND DPP.ISO = @depo_iso)
	BEGIN
		SET @can_renew = 0
		SET @msg = 'ÀÍÀÁÒÉÓ ÅÀËÖÔÀ ÀÒ ÀÒÉÓ ÈÀÅÓÄÁÀÃÉ ÂÀÍÀáËÄÁÉÓ ÐÒÏÃÖØÔÉÓ ÅÀËÖÔÀÓÈÀÍ'
		RETURN 0
	END
	
	SELECT @new_prod_min_amount = AMOUNT_MIN, @new_prod_max_amount = AMOUNT_MAX
	FROM dbo.DEPO_PRODUCT_PROPERTIES (NOLOCK)
	WHERE PROD_ID = @new_prod_id AND ISO = @depo_iso
	
	IF ((@new_prod_min_amount IS NOT NULL) AND (@new_prod_min_amount > @depo_amount)) OR
		((@new_prod_max_amount IS NOT NULL) AND (@new_prod_max_amount < @depo_amount))
	BEGIN
		SET @can_renew = 0
		SET @msg = 'ÀÍÀÁÒÉÓ ÈÀÍáÀ ÀÒ ÛÄÄÓÀÁÀÌÄÁÀ ÂÀÍÀáËÄÁÉÓ ÐÒÏÃÖØÔÉÉÓ ÈÀÍáÄÁÉÓ ËÉÌÉÔÓ'
		RETURN 0
	END
	
	IF @depo_shareable = 1 AND @new_prod_shareable = 3
	BEGIN
		SET @can_renew = 0
		SET @msg = 'ÂÀÍÀáËÄÁÉÓ ÐÒÏÃÖØÔÉÈ ÃÀÖÛÅÄÁÄËÉÀ ÈÀÍÀÌ×ËÏÁÄËÏÁÀ'
		RETURN 0
	END
	
	IF @depo_shareable = 0 AND @new_prod_shareable = 2
	BEGIN
		SET @can_renew = 0
		SET @msg = 'ÂÀÍÀáËÄÁÉÓ ÐÒÏÃÖØÔÉÈ ÈÀÍÀÌ×ËÏÁÄËÏÁÀ ÀÖÝÉËÄÁÄËÉÀ'
		RETURN 0
	END

	IF @new_prod_interest_adv_realize <> 3
	BEGIN
		SET @can_renew = 0
		SET @msg = 'ÂÀÍÀáËÄÁÉÓ ÐÒÏÃÖØÔÉ ÀÒ ÖÍÃÀ ÉÚÏÓ ÓÀÒÂÄÁËÉÓ ßÉÍÀÓßÀÒ ÒÄÀËÉÆÀÝÉÉÈ'
		RETURN 0
	END
	
	RETURN 0
END
GO
