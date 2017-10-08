SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_get_deposit_accumulate_intrate]
	@depo_id int,
	@op_id int = NULL,
	@op_date smalldatetime,
	@date_type tinyint,
	@end_date smalldatetime,
	@iso char(3),
	@intrate_schema int,
	@period int = NULL OUTPUT,
	@intrate money = NULL OUTPUT,
	@return_row bit = 1
AS
BEGIN
	SET NOCOUNT ON;

	IF @date_type = 1
		SET @period = DATEDIFF(day, @op_date, @end_date)
	ELSE
	BEGIN
		SET @period = DATEDIFF(month, @op_date, @end_date)
		IF (@period > 0) AND (DATEADD(month, @period, @op_date) >  @end_date)
				SET @period = @period - 1 
	END;


	WITH intrates([SCHEMA_ID], ISO, ITEMS) AS
	(
		SELECT [SCHEMA_ID], ISO, MAX(ITEMS) AS ITEMS
		FROM dbo.DEPO_PRODUCT_INTRATE_SCHEMA_DETAILS (NOLOCK)
		WHERE [SCHEMA_ID] = @intrate_schema AND ISO = @iso AND ((@period IS NULL) OR (ITEMS <= @period))
		GROUP BY [SCHEMA_ID], ISO
	)
	SELECT @intrate = S.INTRATE
	FROM dbo.DEPO_PRODUCT_INTRATE_SCHEMA_DETAILS  S (NOLOCK)
		INNER JOIN intrates I ON S.[SCHEMA_ID] = I.[SCHEMA_ID] AND S.ISO =  I.ISO AND S.ITEMS = I.ITEMS

	IF @return_row = 1
		SELECT @intrate AS INTRATE, @period AS PERIOD

	RETURN 0
END

GO
