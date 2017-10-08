SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[check_portion_state_out_nbg]
	@date smalldatetime, 
	@por int,
	@user_id int,
	@desired_state1 int,
	@desired_state2 int = -1,
	@desired_state3 int = -1,
	@action_name varchar(100),
	@state int = null OUTPUT 
AS

SET NOCOUNT ON;

SELECT @state = STATE 
FROM impexp.PORTIONS_OUT_NBG 
WHERE PORTION_DATE = @date AND PORTION = @por

IF @state IS NOT NULL AND NOT (@state IN (@desired_state1, @desired_state2, @desired_state3))
BEGIN 
	DECLARE 
		@msg varchar(250),
		@desired_state_name varchar(200)

	SELECT @desired_state_name = impexp.get_state_name (@desired_state1, 0)

	IF @desired_state2 >= 0
		SELECT @desired_state_name = @desired_state_name + CASE WHEN @desired_state3 IS NULL THEN ' ÀÍ' ELSE ',' END + ' ' + impexp.get_state_name (@desired_state2, 0)
		
	IF @desired_state3 >= 0
		SELECT @desired_state_name = @desired_state_name + ' ÀÍ ' + impexp.get_state_name (@desired_state3, 0)

	SET @msg = 'ÀÌ ÐÏÒÝÉÉÓ ' + @action_name + ' ÀÒ ÛÄÉÞËÄÁÀ, ÒÀÃÂÀÍ ÌÉÓÉ ÓÔÀÔÖÓÉ ÀÒ ÀÒÉÓ ' + @desired_state_name

	RAISERROR (@msg, 16, 1)
	RETURN 1
END

RETURN 0
GO
