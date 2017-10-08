SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_get_deposit_intrate_period]
	@depo_id int,
	@op_id int = NULL,
	@date smalldatetime,
	@op_date smalldatetime,	
	@date_type tinyint,
	@end_date smalldatetime,
	@iso char(3),
	@intrate_schema int
AS
BEGIN
SET NOCOUNT ON;

DECLARE
	@interest_correction money
	
SELECT @interest_correction = P.INTEREST_CORRECTION
FROM dbo.DEPO_DEPOSITS D (NOLOCK)
	INNER JOIN dbo.DEPO_PRODUCT P (NOLOCK) ON P.PROD_ID = D.PROD_ID
WHERE D.DEPO_ID = @depo_id

DECLARE
	@period int,
	@period2 int

	IF @date_type = 1
		SET @period = DATEDIFF(day, @date, @end_date)
	ELSE
	BEGIN
		SET @period = DATEDIFF(month, @date, @end_date)
		IF (@period > 0) AND (DATEADD(month, @period, @date) >  @end_date)
				SET @period = @period - 1 
	END;

	IF @date_type = 1
		SET @period2 = DATEDIFF(day, @op_date, @end_date)
	ELSE
	BEGIN
		SET @period2 = DATEDIFF(month, @op_date, @end_date)
		IF (@period2 > 0) AND (DATEADD(month, @period2, @op_date) >  @end_date)
				SET @period2 = @period2 - 1 
	END;


	WITH intrates([SCHEMA_ID], ISO, ITEMS) AS
	(
		SELECT [SCHEMA_ID], ISO, MAX(ITEMS) AS ITEMS
		FROM dbo.DEPO_PRODUCT_INTRATE_SCHEMA_DETAILS (NOLOCK)
		WHERE [SCHEMA_ID] = @intrate_schema AND ISO = @iso AND ((@period IS NULL) OR (ITEMS <= @period))
		GROUP BY [SCHEMA_ID], ISO
	)
	SELECT S.INTRATE + ISNULL(@interest_correction, $0.00) AS INTRATE, @period2 AS PERIOD
	FROM dbo.DEPO_PRODUCT_INTRATE_SCHEMA_DETAILS  S (NOLOCK)
		INNER JOIN intrates I ON S.[SCHEMA_ID] = I.[SCHEMA_ID] AND S.ISO =  I.ISO AND S.ITEMS = I.ITEMS

	RETURN
END

GO
