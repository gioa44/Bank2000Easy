SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[show_val_rates] ( @start_date smalldatetime = null, @end_date smalldatetime = null, @iso TISO = null)
RETURNS @rates TABLE (ISO char(3), DT smalldatetime, ITEMS int, AMOUNT money, RATE_DT smalldatetime, PRIMARY KEY (ISO, DT))
AS
BEGIN

	SET @start_date = ISNULL(@start_date, 0)
	
	IF @end_date IS NULL
		SELECT @end_date = MAX(DT)
		FROM dbo.VAL_RATES (NOLOCK)
	
	INSERT INTO @rates
	SELECT R.*, R.DT
	FROM dbo.VAL_RATES R
		INNER JOIN dbo.VAL_CODES C ON C.ISO = R.ISO
	WHERE C.IS_DISABLED = 0 AND R.DT >= @start_date AND R.DT <= @end_date AND (@iso IS NULL OR C.ISO = @iso)
	
	DECLARE 
		@dt smalldatetime,
		@items int,
		@amount money
	
	DECLARE cc CURSOR FAST_FORWARD LOCAL
	FOR
	SELECT ISO FROM dbo.VAL_CODES WHERE IS_DISABLED = 0 AND (@iso IS NULL OR ISO = @iso)
	
	OPEN cc
	FETCH NEXT FROM cc INTO @iso
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @dt = MIN(DT)
		FROM @rates
		WHERE ISO = @iso AND DT >= @start_date
	
		IF @dt IS NULL
		BEGIN
			SELECT @dt = MAX(DT)
			FROM dbo.VAL_RATES (NOLOCK)
			WHERE ISO = @iso AND DT < @start_date
	
			SELECT @items = ITEMS, @amount = AMOUNT
			FROM dbo.VAL_RATES (NOLOCK)
			WHERE ISO = @iso AND DT = @dt
		END
		ELSE
		BEGIN
			SELECT @items = ITEMS, @amount = AMOUNT
			FROM @rates
			WHERE ISO = @iso AND DT = @dt
		END
	
		DECLARE @rate_dt smalldatetime
		SET @rate_dt = @dt

		IF @dt IS NOT NULL
		BEGIN
			IF @dt < @start_date
				SET @dt = @start_date
	
			WHILE @dt <= @end_date
			BEGIN
				IF NOT EXISTS(SELECT * FROM @rates WHERE ISO = @iso AND DT = @dt)
					INSERT INTO @rates VALUES (@iso, @dt, @items, @amount, @rate_dt)
				ELSE
					SELECT @items = ITEMS, @amount = AMOUNT, @rate_dt = @dt
					FROM @rates
					WHERE ISO = @iso AND DT = @dt
	
				SET @dt = @dt + 1
			END
		END
		
		FETCH NEXT FROM cc INTO @iso
	END

	RETURN
END
GO
