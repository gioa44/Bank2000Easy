SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[depo_sp_check_op_on_user]
	@depo_id int,
	@op_date smalldatetime,
	@op_type smallint,
	@op_state bit,
	@op_amount money,
	@op_iso CHAR(3),
	@op_data XML ,
	@user_id int
AS
SET NOCOUNT ON;
	
	DECLARE
		@str varchar(100),
		@prod_id int,
		@iso varchar(3),
		@depo_amount money,
		@withdraw_intrate money

	SELECT @prod_id = PROD_ID, @depo_amount = AMOUNT, @iso = ISO
	FROM dbo.DEPO_DEPOSITS
	WHERE DEPO_ID = @depo_id


	IF @op_type = dbo.depo_fn_const_op_withdraw()
	BEGIN
		SET @withdraw_intrate = NULL
		SELECT @withdraw_intrate = CONVERT(money, ATTRIB_VALUE)
		FROM dbo.DEPO_PRODUCT_ATTRIBUTES
		WHERE PROD_ID = @prod_id AND ATTRIB_CODE = 'WTHDR_MAX'	

		IF @withdraw_intrate IS NOT NULL
		BEGIN
			IF @op_amount > ROUND(@depo_amount / 100.00 * @withdraw_intrate, $0.00)
			BEGIN
				SET @str = 'ÀÍÀÁÒÉÓ ÍÀÛÈÉÓ ' + CONVERT(varchar(20), @withdraw_intrate) + '%%  ÌÄÔÉ ÈÀÍáÉÓ ÂÀÔÀÍÀ áÄËÛÄÊÒÖËÄÁÉÈ ÃÀÖÛÅÄÁÄËÉÀ';
				RAISERROR(@str, 16, 1);
				RETURN 1
			END
		END
	END
RETURN 0
GO
