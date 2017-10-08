SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [easy].[calculate_effective_rate]
	@loan_id int,
	@date smalldatetime
	--@source int,
AS
BEGIN
	DECLARE
		@rc int,		
		@fault_reason nvarchar(max),
		@schedule_xml xml
	
	DECLARE
		@start_date smalldatetime,
		@end_date smalldatetime,
		@loan_amount money,
		@used_amount money,
		@loan_ccy char(3),
		@admin_fee money,
		@fee1 money,
		@fee2 money,
		@fee3 money,
		@save_result bit,
		@return_fees bit,
		@inflation_rate money,
		@h TRATE,
		@generic_schedule bit,
		@code_prefix varchar(50)

	SET @return_fees = 1
	SET @inflation_rate = 0.15
	SET @code_prefix = ''

	SELECT 
		@start_date = l.START_DATE, 
		@end_date = l.END_DATE, 
		@loan_amount = l.AMOUNT, 
		@used_amount = l.AMOUNT,
		@loan_ccy = l.ISO,
		@admin_fee = l.ADMIN_FEE
	FROM dbo.LOANS l
	WHERE l.LOAN_ID = @loan_id

	--SELECT
	--	@fee1 = p.EFFR_EXPENSE_GEL_NOTARY_FEES,
	--	@fee2 = p.EFFR_EXPENSE_GEL_PUBLIC_REGISTER,
	--	@fee3 = p.EFFR_EXPENSE_GEL_VALUATION
	--FROM dbo.LOAN_ATTRIBUTES a
	--	PIVOT ( MAX(a.ATTRIB_VALUE) FOR a.ATTRIB_CODE IN ( 
	--		EFFR_EXPENSE_GEL_NOTARY_FEES,
	--		EFFR_EXPENSE_GEL_PUBLIC_REGISTER,
	--		EFFR_EXPENSE_GEL_VALUATION) 
	--	) AS p
	--WHERE p.LOAN_ID = @loan_id

	IF @start_date = @end_date
		RETURN 0;

	CREATE TABLE #T
	(
		RATE_TYPE int PRIMARY KEY,
		CODE varchar(50) COLLATE Latin1_General_BIN
							NOT NULL,
		DESCRIPTION nvarchar(512) COLLATE Latin1_General_BIN,
		RATE decimal(20, 8),
		CASH_FLOW xml NULL
	);

DECLARE
	@CASH_FLOW easy.t_CashFlow

	INSERT INTO @CASH_FLOW (FLOW_TYPE, [DATE], AMOUNT, NAME) 
	VALUES('DISBURSE', @date, @used_amount, N'ათვისება');
	
	IF (@admin_fee IS NOT NULL AND @admin_fee > 0)
	BEGIN
		INSERT INTO @CASH_FLOW (FLOW_TYPE, [DATE], AMOUNT, NAME)
		SELECT 'DISBURSE_ADMIN_FEE', @start_date, ROUND(-@admin_fee, 2), N'გაცემის საკომისიო';
	END

	INSERT INTO @CASH_FLOW (FLOW_TYPE, [DATE], AMOUNT, AMOUNT_NOMINAL, CCY_NOMINAL, NAME)
	SELECT
		'EXTRA_EXPENSE_' + a.ATTRIB_CODE,
		@start_date,
		-ROUND(CAST(a.ATTRIB_VALUE AS money) * dbo.get_cross_rate (CASE WHEN a.ATTRIB_CODE LIKE '%GEL%' THEN 'GEL' ELSE l.ISO END, l.ISO, @date), 2),
		-CAST(a.ATTRIB_VALUE AS money),
		'GEL',
		ac.DESCRIP_LAT
	FROM dbo.LOAN_ATTRIBUTES a
		INNER JOIN dbo.LOAN_ATTRIB_CODES ac ON ac.CODE = a.ATTRIB_CODE
		INNER JOIN dbo.LOANS l ON l.LOAN_ID = a.LOAN_ID
	WHERE a.ATTRIB_CODE LIKE '%EFFR_EXPENSE%' AND CAST(a.ATTRIB_VALUE AS money) > 0.0
		
	DECLARE
		@expanse_type_id nvarchar(512), 
		@period_type tinyint,
		@interval_type tinyint,
		@interval_step tinyint,
		@onetime_fee_date smalldatetime,
		@_date smalldatetime,		
		@ccy char(3),
		@expanse_amount money,
		@expanse_amount_nominal money,
		@expanse_name nvarchar(250)


	IF @schedule_xml IS NULL
	BEGIN
	    SET @schedule_xml = (
							SELECT
								ls.SCHEDULE_DATE AS date,
								ISNULL(ls.ORIGINAL_PRINCIPAL, 0) + ISNULL(ls.ORIGINAL_INTEREST, 0) AS value,
								ls.ORIGINAL_PRINCIPAL AS principal,
								ls.ORIGINAL_INTEREST AS interest,
								BALANCE AS balance
							FROM dbo.LOAN_SCHEDULE ls (NOLOCK)
							WHERE ls.LOAN_ID = @loan_id
							FOR XML	RAW('item'), ROOT('payments'), TYPE);
	END

	IF (@schedule_xml IS NOT NULL)
	BEGIN
		INSERT INTO @CASH_FLOW (FLOW_TYPE, [DATE], AMOUNT, NAME)
			SELECT 
				'LOAN_PAYMENT',
				t.c.value('@date', 'smalldatetime'),
				-t.c.value('@value', 'money'),
				N'დაფარვა'
			FROM @schedule_xml.nodes('payments/item') t(c)
			WHERE -t.c.value('@value', 'money') IS NOT NULL
	END
	
	DELETE FROM @CASH_FLOW WHERE AMOUNT = 0;

	; WITH t AS (
		SELECT YearSpan,
			   --easy.effr_YearSpan(MIN(DATE) OVER (ORDER BY DATE ROWS UNBOUNDED PRECEDING), DATE) AS YearSpan_New,
			   easy.effr_YearSpan(MIN(DATE) OVER (), DATE) AS YearSpan_New
		FROM @CASH_FLOW
	)
	UPDATE t SET t.YearSpan = t.YearSpan_New

	DECLARE
		@cash_flow_xml xml,
		@effective_rate float

	SET @cash_flow_xml = (
				SELECT [DATE], AMOUNT, FLOW_TYPE, NAME, YearSpan 
				FROM @CASH_FLOW 
				ORDER BY [DATE] FOR XML RAW ('schedule'), TYPE);

	IF EXISTS(SELECT * FROM @CASH_FLOW WHERE FLOW_TYPE = 'LOAN_PAYMENT')
	BEGIN
		EXEC easy.effr_Calculate @cashFlow = @CASH_FLOW, @result = @effective_rate OUT
		SET @effective_rate = @effective_rate * 100.00

		INSERT INTO #T
			SELECT 0, 'STD' + @code_prefix, N'ეფექტური %', @effective_rate, @cash_flow_xml
	END

	--EXEC @rc = pipeline.on_calculate_effective_rate @application_id = @loan_id,
    --    @save_result = @save_result, @loan_properties = @loan_properties,
    --    @args = @args;
	
	--IF (@rc <> 0 OR @@ERROR <> 0)
	--BEGIN
	--	--DROP TABLE #T;
	--	--DROP TABLE @CASH_FLOW;
	--	RETURN 1;
	--END
	
	SET @h = (POWER(1 + @inflation_rate, easy.effr_YearSpan(@date, @end_date)) - 1) / DATEDIFF(DAY, @date, @end_date);

	DECLARE
		@rates table(CCY char(3) NOT NULL, RATE money)

	INSERT INTO @rates(CCY, RATE)
		SELECT DISTINCT(ISNULL(CCY_NOMINAL, @loan_ccy)), dbo.get_cross_rate(ISNULL(CCY_NOMINAL, @loan_ccy), 'GEL', @date)
		FROM @CASH_FLOW
		WHERE ISNULL(CCY_NOMINAL, @loan_ccy) <> 'GEL'

	UPDATE @CASH_FLOW
		SET AMOUNT = ISNULL(c.AMOUNT_NOMINAL, c.AMOUNT) * (r.RATE * (1 + @h * DATEDIFF(DAY, @date, c.[DATE])))
	FROM @CASH_FLOW c 
		INNER JOIN @rates r ON r.CCY =  ISNULL(c.CCY_NOMINAL, @loan_ccy)
	WHERE ISNULL(CCY_NOMINAL, @loan_ccy) <> 'GEL'

	IF (@@ROWCOUNT > 0)
	BEGIN
		IF (@loan_ccy <> 'GEL')
		BEGIN
			UPDATE @CASH_FLOW
				SET AMOUNT = AMOUNT_NOMINAL
			WHERE CCY_NOMINAL = 'GEL'
		END

		SET @cash_flow_xml = (
			SELECT [DATE], AMOUNT, FLOW_TYPE, NAME 
			FROM @CASH_FLOW 
			ORDER BY [DATE] FOR XML RAW ('schedule'), TYPE
		);
		
		IF EXISTS(SELECT TOP 1 * FROM @CASH_FLOW WHERE FLOW_TYPE = 'LOAN_PAYMENT')
		BEGIN
			EXEC easy.effr_Calculate @cashFlow = @CASH_FLOW, @result = @effective_rate OUT
			SET @effective_rate = @effective_rate * 100.00

			INSERT INTO #T
				SELECT 1, 'INFL' + @code_prefix, N'ეფექტური % (ინფლაციის გათვალისწინებით)', @effective_rate, @cash_flow_xml
		END
	END
	
	--IF (@save_result = 1)
	--BEGIN
	--	DELETE FROM loan.EFFECTIVE_RATES
	--	WHERE LOAN_ID = @loan_id AND CODE IN (SELECT CODE FROM #T);

	--	INSERT INTO loan.EFFECTIVE_RATES (LOAN_ID, CODE, [DESCRIPTION], RATE, CASH_FLOW)
	--	SELECT @loan_id, CODE, [DESCRIPTION], RATE, CASH_FLOW FROM #T WHERE RATE IS NOT NULL;
	--END

	IF (@return_fees = 1)
	BEGIN
		SELECT 
			RATE_TYPE, CODE, [DESCRIPTION], CAST(RATE AS money), CASH_FLOW 
		FROM #T
	END

	DROP TABLE #T;	
END
GO
