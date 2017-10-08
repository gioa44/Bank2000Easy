SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[loan_get_loan_collateral_data](@loan_id int, @date smalldatetime)
RETURNS
	@loan_collateral_data TABLE (
		LOAN_ID int NOT NULL,
		DESCRIP varchar(100) NOT NULL,
		DESCRIP_LAT varchar(100) NULL,
		AMOUNT money NOT NULL,
		MAIN_COLLATERAL_LIST varchar(200) NULL
)
     
AS
BEGIN
	DECLARE 
		@main_collateral_list varchar(200),
		@collateral_type int,
		@descrip varchar(100),
		@descrip_lat varchar(100),
		@amount money

	SELECT @main_collateral_list = MAIN_COLLATERAL_LIST
	FROM dbo.LOANS (NOLOCK)
	WHERE LOAN_ID = @loan_id

	IF @main_collateral_list = ''
		SET @main_collateral_list = NULL

	IF @main_collateral_list IS NULL
	BEGIN
		SELECT @main_collateral_list = B.MAIN_COLLATERAL_LIST
		FROM dbo.LOANS A (NOLOCK)
			INNER JOIN dbo.LOAN_CREDIT_LINES B (NOLOCK) ON A.CREDIT_LINE_ID = B.CREDIT_LINE_ID
		WHERE A.LOAN_ID = @loan_id
	END

	IF @main_collateral_list IS NOT NULL
	BEGIN
		SELECT TOP 1
			@amount = SUM(dbo.get_equ(AMOUNT, ISO, @date)), @collateral_type = COLLATERAL_TYPE
		FROM dbo.LOAN_COLLATERALS (NOLOCK)
		WHERE COLLATERAL_ID IN (SELECT ID FROM dbo.fn_split_list_int(@main_collateral_list, ','))
		GROUP BY COLLATERAL_TYPE

		SELECT @descrip = DESCRIP, @descrip_lat = DESCRIP_LAT
		FROM dbo.LOAN_COLLATERAL_TYPES (NOLOCK)
		WHERE [TYPE_ID] = @collateral_type

		INSERT INTO @loan_collateral_data (LOAN_ID, DESCRIP, DESCRIP_LAT, AMOUNT, MAIN_COLLATERAL_LIST)
		VALUES(@loan_id, ISNULL(@descrip, 'N/A'), @descrip_lat, ISNULL(@amount, $0.00), @main_collateral_list)
	END
	ELSE
	BEGIN
		IF EXISTS (SELECT * FROM dbo.LOAN_COLLATERALS_LINK (NOLOCK) WHERE LOAN_ID = @loan_id)
		BEGIN
			INSERT INTO @loan_collateral_data (LOAN_ID, DESCRIP, DESCRIP_LAT, AMOUNT, MAIN_COLLATERAL_LIST)
			VALUES(@loan_id, 'ÌÉÁÌÖËÉ ÀØÅÓ ÂÉÒÀÏ', 'Collaterals Linked', $0.00, NULL)
		END
		ELSE
		BEGIN
			INSERT INTO @loan_collateral_data (LOAN_ID, DESCRIP, DESCRIP_LAT, AMOUNT, MAIN_COLLATERAL_LIST)
			VALUES(@loan_id, 'ÂÉÒÀÏ ÀÒ ÀØÅÓ', 'No Collaterals', $0.00, NULL)	
		END
	END
	
RETURN
END
GO
