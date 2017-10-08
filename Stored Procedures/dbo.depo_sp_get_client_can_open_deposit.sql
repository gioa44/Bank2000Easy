SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_get_client_can_open_deposit]
	@client_type int,
	@birth_date smalldatetime,
	@sys_bank_date smalldatetime
AS	
BEGIN
	SET NOCOUNT ON;

	DECLARE
		@can_open_type tinyint
		
	/*	0 - ÀÍÀÁÒÉÓ ÂÀáÓÍÀ ÀÒ ÛÉÞËÄÁÀ
		1 - ÛÄÖÞËÉÀ ÊËÉÄÍÔÓ ÂÀáÓÍÀÓ ÀÍÀÁÀÒÉ
		2 - ÊËÉÄÍÔÉ ÁÀÅÛÅÉÀ, ÀÖÝÉËÄÁÄËÉÀ ÈÀÍáÉÓ ÛÄÌÏÌÔÀÍÉ
		3 - ÊËÉÄÍÔÉ ÀÒÀ×ÉÆÉÊÖÒÉ ÐÉÒÉÀ, ÀÖÝÉËÄÁÄËÉÀ ÌÉÍÃÏÁÉËÏÁÀ
	*/
	
	SET @can_open_type = 0
	
	IF @client_type = 1
	BEGIN
		IF (@birth_date IS NOT NULL) AND (DATEADD(year, 18, @birth_date) > @sys_bank_date)
			SET @can_open_type = 2
		ELSE
			SET @can_open_type = 1
	END
	ELSE
		SET @can_open_type = 3
		
	SELECT @can_open_type AS CAN_OPEN_TYPE
END

GO
