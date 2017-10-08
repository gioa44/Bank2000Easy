SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_get_formula] (@oid int)
RETURNS varchar(255)
AS
BEGIN
	DECLARE
		@formula varchar(255),
		@did int,
		@prod_id int,
		@iso TISO,
		@int_rate money

	DECLARE
		@range_1 money,
		@range_2 money,
		@r1 varchar(20),
		@r2 varchar(20),
		@rate varchar(10)

	SELECT @did = DEPO_ID
	FROM dbo.DEPO_OPS (NOLOCK)
	WHERE OP_ID = @oid

	SELECT @iso = ISO, @prod_id = PROD_ID
	FROM dbo.DEPOS (NOLOCK)
	WHERE DEPO_ID = @did
	
	SET @int_rate = 0
	SELECT @int_rate = ISNULL(INT_RATE, 0)
	FROM dbo.DEPO_DATA (NOLOCK)
	WHERE OP_ID = @oid
  
	SELECT @range_1 = MIN_AMOUNT, @range_2 = MAX_AMOUNT
	FROM dbo.DEPO_PROD_RANGE_AMOUNTS (NOLOCK)
	WHERE PROD_ID = @prod_id AND ISO = @iso
	
	SET @rate = '-' + convert(varchar(10), @int_rate)
	SET @r1 = '-' + convert(varchar(20), @range_1)
	SET @r2 = '-' + convert(varchar(20), @range_2)

	IF @range_1 IS NULL AND @range_2 IS NULL 
		SET @formula = 'CASE WHEN AMOUNT<-0 THEN AMOUNT*' + @rate + ' ELSE 0 END'
	ELSE
	IF @range_2 IS NULL 
		SET @formula = 'CASE WHEN AMOUNT<' + @r1 + ' THEN AMOUNT*' + @rate + ' ELSE 0 END'
	ELSE
	IF @range_1 IS NULL 
		SET @formula = 'CASE WHEN AMOUNT<' + @r2 + ' THEN ' + @r2 + '*' + @rate + ' WHEN AMOUNT<-0 THEN AMOUNT*' + @rate + ' ELSE 0 END'
	ELSE
	BEGIN
		SET @formula = 'CASE WHEN AMOUNT<' + @r2 + ' THEN ' + @r2 + '*' + @rate + ' WHEN AMOUNT<' + @r1 + ' THEN AMOUNT*' + @rate + ' ELSE 0 END'
	END

	RETURN @formula
END
GO
