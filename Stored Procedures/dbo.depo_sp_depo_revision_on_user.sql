SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_depo_revision_on_user]
	@depo_id int,
	@new_intrate money OUTPUT
AS
SET NOCOUNT ON;

DECLARE
	@r int

DECLARE
	@prod_id int,
	@iso CHAR(3),
	@period int,
	@interest_correction money,
	@intrate_schema int,
	@child_deposit bit
	
SELECT @prod_id = PROD_ID, @iso = ISO, @period = PERIOD, @intrate_schema = INTRATE_SCHEMA, @child_deposit = CHILD_DEPOSIT
FROM dbo.DEPO_DEPOSITS (NOLOCK)
WHERE DEPO_ID = @depo_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 RETURN 1;

SELECT @interest_correction = INTEREST_CORRECTION
FROM dbo.DEPO_PRODUCT (NOLOCK)
WHERE PROD_ID = @prod_id

IF @child_deposit = 0
BEGIN
	WITH intrates([SCHEMA_ID], ISO, ITEMS) AS
	(
		SELECT [SCHEMA_ID], ISO, MAX(ITEMS) AS ITEMS
		FROM dbo.DEPO_PRODUCT_INTRATE_SCHEMA_DETAILS (NOLOCK)
		WHERE [SCHEMA_ID] = @intrate_schema AND ISO = @iso AND ((@period IS NULL) OR (ITEMS <= @period))
		GROUP BY [SCHEMA_ID], ISO
	)
	SELECT @new_intrate = S.INTRATE + ISNULL(@interest_correction, $0.00)
	FROM dbo.DEPO_PRODUCT_INTRATE_SCHEMA_DETAILS  S (NOLOCK)
		INNER JOIN intrates I ON S.[SCHEMA_ID] = I.[SCHEMA_ID] AND S.ISO =  I.ISO AND S.ITEMS = I.ITEMS
END
ELSE
BEGIN -- საბავშვო ანაბრის შემთხვევაში
	DECLARE
		@intrate_prod_id int
		
	SET @intrate_prod_id = 41
	
	SELECT TOP 1 @new_intrate = INTRATE
	FROM dbo.DEPO_PRODUCT_INTRATE_SCHEMA_DETAILS S (NOLOCK)
		INNER JOIN dbo.DEPO_PRODUCT P (NOLOCK) ON P.INTRATE_SCHEMA = S.[SCHEMA_ID]
	WHERE P.PROD_ID = @intrate_prod_id AND S.ISO = @iso
	ORDER BY S.ITEMS DESC
END	
RETURN 0

GO
