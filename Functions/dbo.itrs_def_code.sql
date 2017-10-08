SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[itrs_def_code] (@rec_type int, @is_juridical bit, @is_resident2 bit, @amount money, @doc_type tinyint)
RETURNS varchar(4)
AS
BEGIN
	DECLARE @code int

	SET @code = NULL
		
	IF @rec_type IN (4,8) AND @is_resident2 = 0
	BEGIN
		IF @rec_type = 4
			SET @code = 8443
		ELSE
			SET @code = 8444
		
		RETURN @code
	END

	IF (@is_juridical = 1 AND @amount < $10000) OR (@is_juridical = 0 AND @amount < $5000)
	BEGIN
		IF @rec_type IN (2,8) -- debit
			SET @code = 8022
		ELSE 
			SET @code = 8021
		
		RETURN @code
	END

	IF @rec_type IN (4,8)
	BEGIN
		BEGIN
			IF @doc_type = 20 -- გაყიდვა
				SET @code = '8446'
			ELSE
			IF @doc_type = 14 -- ყიდვა
				SET @code = '8445'
			ELSE
			IF @doc_type BETWEEN 120 AND 129 -- შემოსავალი
				SET @code = '8447'
			ELSE
			IF @doc_type BETWEEN 130 AND 149 -- გასავალი
				SET @code = '8448'
		END
	END

	RETURN @code
END
GO
