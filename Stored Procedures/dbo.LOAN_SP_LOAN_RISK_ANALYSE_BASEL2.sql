SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[LOAN_SP_LOAN_RISK_ANALYSE_BASEL2]
	@loan_id int,
	@date smalldatetime,
	@principal money, 
	@late_principal money,
	@overdue_principal money,
	@calloff_principal money,
	@writeoff_principal money,

	@category_1 money OUTPUT,
	@category_2 money OUTPUT,
	@category_3 money OUTPUT,
	@category_4 money OUTPUT,
	@category_5 money OUTPUT,
	@category_6 money OUTPUT,
	@max_category_level tinyint OUTPUT
AS
BEGIN
SET NOCOUNT ON

IF EXISTS(SELECT * FROM dbo.LOAN_OPS WHERE LOAN_ID = @loan_id AND OP_TYPE = dbo.loan_const_op_restructure_risks())
BEGIN
	SELECT 
		@category_1 = CASE WHEN @category_1 IS NULL THEN CATEGORY_1 ELSE @category_1 END,
		@category_2 = CASE WHEN @category_2 IS NULL THEN CATEGORY_2 ELSE @category_2 END,
		@category_3 = CASE WHEN @category_3 IS NULL THEN CATEGORY_3 ELSE @category_3 END,
		@category_4 = CASE WHEN @category_4 IS NULL THEN CATEGORY_4 ELSE @category_4 END,
		@category_5 = CASE WHEN @category_5 IS NULL THEN CATEGORY_5 ELSE @category_5 END,
		@category_6 = CASE WHEN @category_6 IS NULL THEN CATEGORY_6 ELSE @category_6 END,
		@max_category_level = MAX_CATEGORY_LEVEL 
	FROM dbo.LOAN_DETAILS
	WHERE LOAN_ID = @loan_id

	GOTO _ret
END

IF @writeoff_principal <> $0.00
BEGIN
	SET @category_1 = $0.00
	SET @category_2 = $0.00
	SET @category_3 = $0.00
	SET @category_4 = $0.00
	SET @category_5 = $0.00
	SET @category_6 = @writeoff_principal
	SET @max_category_level = 6

	GOTO _ret
END

DECLARE
	@max_category_level_ tinyint

SELECT @max_category_level_ = MAX_CATEGORY_LEVEL 
FROM dbo.LOAN_DETAILS
WHERE LOAN_ID = @loan_id

DECLARE
	@loan_iso TISO,
	@ensure_amount money,
	@loan_amount money,
	@loan_ensured_amount money,
	@loan_not_ensured_amount money,
	@type_id int,
	@product_id int,
	@reserve_max_category bit,
	@ensure_type tinyint,
	@_credit_line_id int,

	@a money,
	@b money,
	@c money,
	@d money

SELECT @product_id = PRODUCT_ID, @loan_iso = ISO, @type_id = RISK_TYPE, 
	@reserve_max_category = RESERVE_MAX_CATEGORY, @ensure_type = ENSURE_TYPE, @_credit_line_id = CREDIT_LINE_ID 
FROM dbo.LOANS
WHERE LOAN_ID = @loan_id

SET @loan_amount = @principal + @late_principal + @overdue_principal + @calloff_principal
SET @loan_ensured_amount = $0.00
SET @loan_not_ensured_amount = @loan_amount

IF @ensure_type IN (1, 2) --ÖÆÒÖÍÅÄËÚÏ×ÉËÉ ÀÍ ÍÀßÉËÏÁÒÉÅ ÖÆÒÖÍÅÄËÚÏ×ÉËÉ
BEGIN
	SET @ensure_amount = $0.00
	
	SELECT @a = SUM(dbo.get_cross_amount(AMOUNT, ISO, @loan_iso, @date))
	FROM dbo.LOAN_COLLATERALS (NOLOCK)
	WHERE LOAN_ID = @loan_id AND COLLATERAL_TYPE <> 6 --ÌÄÓÀÌÄ ÐÉÒÉÓ ÂÀÒÀÍÔÉÀ
	--OPTION (RECOMPILE)

	SELECT @b = SUM(dbo.get_cross_amount(C.AMOUNT, C.ISO, @loan_iso, @date))
	FROM dbo.LOAN_COLLATERALS C (NOLOCK)
		INNER JOIN dbo.LOAN_COLLATERALS_LINK LNK (NOLOCK) ON C.COLLATERAL_ID = LNK.COLLATERAL_ID
	WHERE LNK.LOAN_ID = @loan_id AND C.COLLATERAL_TYPE <> 6 --ÌÄÓÀÌÄ ÐÉÒÉÓ ÂÀÒÀÍÔÉÀ
	--OPTION (RECOMPILE)

	IF @_credit_line_id IS NOT NULL
	BEGIN
		SELECT @c = SUM(dbo.get_cross_amount(C.AMOUNT, C.ISO, @loan_iso, @date))
		FROM dbo.LOAN_COLLATERALS  C (NOLOCK)
		WHERE C.CREDIT_LINE_ID = @_credit_line_id AND C.COLLATERAL_TYPE <> 6 --ÌÄÓÀÌÄ ÐÉÒÉÓ ÂÀÒÀÍÔÉÀ
		OPTION (RECOMPILE)

		SELECT @d = SUM(dbo.get_cross_amount(C.AMOUNT, C.ISO, @loan_iso, @date))
		FROM dbo.LOAN_COLLATERALS C (NOLOCK)
			INNER JOIN dbo.LOAN_CREDIT_LINE_COLLATERALS_LINK LNK (NOLOCK) ON C.COLLATERAL_ID = LNK.COLLATERAL_ID
		WHERE C.CREDIT_LINE_ID = @_credit_line_id AND C.COLLATERAL_TYPE <> 6 --ÌÄÓÀÌÄ ÐÉÒÉÓ ÂÀÒÀÍÔÉÀ
		OPTION (RECOMPILE)
	END

	SET @ensure_amount = ISNULL(@a, $0.00) + ISNULL(@b, $0.00) + ISNULL(@c, $0.00) + ISNULL(@d, $0.00)

	IF @ensure_amount >= @loan_amount  
	BEGIN
		SET @loan_ensured_amount = @loan_amount
		SET @loan_not_ensured_amount = $0.00
	END
	ELSE
	BEGIN
		SET @loan_ensured_amount = @ensure_amount
		SET @loan_not_ensured_amount = @loan_amount - @ensure_amount
	END		
END

DECLARE
	@min_overdue_date smalldatetime,
	@overdue_days int

SELECT @min_overdue_date = MIN(OVERDUE_DATE)
FROM dbo.LOAN_DETAIL_OVERDUE
WHERE LOAN_ID = @loan_id AND (OVERDUE_PRINCIPAL <> $0.00 OR OVERDUE_PERCENT <> $0.00)

SET @overdue_days = DATEDIFF(day, ISNULL(@min_overdue_date, @date), @date)

SET @category_1 = $0.00
SET @category_2 = $0.00
SET @category_3 = $0.00
SET @category_4 = $0.00
SET @category_5 = $0.00
SET @category_6 = $0.00

IF @overdue_days <= 30
BEGIN
	IF @max_category_level_ >= 2
	BEGIN
		SET @category_2 = @loan_amount
		SET @max_category_level = 2
	END
	ELSE
	BEGIN
		SET @category_1 = @loan_amount
		SET @max_category_level = 1
	END
END
ELSE
IF @overdue_days > 30 AND @overdue_days <= 60
BEGIN
	SET @category_2 = @loan_amount
	SET @max_category_level = 2
END
ELSE
IF @overdue_days > 60 AND @overdue_days <= 90
BEGIN
	IF @loan_not_ensured_amount = $0.00
	BEGIN
		SET @category_2 = @loan_amount
		SET @max_category_level = 2
	END
	ELSE
	BEGIN
		SET @category_3 = @loan_amount
		SET @max_category_level = 3
	END
END
ELSE
IF @overdue_days > 90 AND @overdue_days <= 120
BEGIN
	SET @category_3 = @loan_amount
	SET @max_category_level = 3
END
ELSE
IF @overdue_days > 120 AND @overdue_days <= 150
BEGIN
	IF @loan_not_ensured_amount = $0.00
	BEGIN
		SET @category_3 = @loan_amount
		SET @max_category_level = 3
	END
	ELSE
	IF @loan_ensured_amount = $0.00
	BEGIN
		SET @category_4 = @loan_amount
		SET @max_category_level = 4
	END
	ELSE
	BEGIN
		SET @category_3 = @loan_ensured_amount
		SET @category_4 = @loan_not_ensured_amount
		SET @max_category_level = 4
	END
END
ELSE
IF @overdue_days > 150 AND @overdue_days <= 180
BEGIN
	SET @category_4 = @loan_amount
	SET @max_category_level = 4
END
ELSE
IF @overdue_days > 180
BEGIN
	SET @category_5 = @loan_amount
	SET @max_category_level = 5
END

_ret:
RETURN 0
END

GO
