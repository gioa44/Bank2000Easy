SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[fp_get_tariff_info_send] (@fp_sys_id int, @country char(2), @amount money, @iso char(3))
RETURNS @tbl TABLE (TARIFF1 money, TARIFF2 money)
AS
BEGIN
	DECLARE 
		@is_cis bit,
		@fee1 money,
		@fee2 money
	
	SET @fee1 = NULL
	SET @fee2 = NULL
	
	SET @is_cis = 0
	IF @country IN ('RU', 'UA', 'BY', 'AZ', 'AM', 'MD', 'KZ', 'UZ', 'TM', 'TJ', 'KG')
		SET @is_cis = 1
		
	IF @fp_sys_id = 1 -- WU
	BEGIN
		SET @fee1 = @amount * $0.01
		SET @fee2 = @amount * $0.02
	END
	ELSE
	IF @fp_sys_id = 2 -- CT
	BEGIN
		SET @fee1 = @amount * $0.015
		SET @fee2 = @amount * $0.02
	END
	ELSE
	IF @fp_sys_id = 3 -- US
	BEGIN
		SET @fee2 = @amount * $0.02
	END
	
	INSERT INTO @tbl VALUES(@fee1, @fee2)
	
	RETURN
END
GO
