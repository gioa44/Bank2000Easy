SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_LOAN_PROCESSING_VIRTUAL]
	@date smalldatetime,
	@user_id int,
	@loan_id int,
	@create_tables bit=1
AS
SET NOCOUNT ON

IF @create_tables = 1
BEGIN
	CREATE TABLE #tbl_details(	LOAN_ID int NOT NULL,
		CALC_DATE smalldatetime NOT NULL,
		PREV_STEP smalldatetime NOT NULL,
		NU_PRINCIPAL money NULL,
		NU_INTEREST money NULL,
		NU_INTEREST_DAILY money NULL,
		NU_INTEREST_FRACTION decimal(16,15) NULL,
		PRINCIPAL money NULL,
		INTEREST money NULL,
		INTEREST_DAILY money NULL,
		INTEREST_FRACTION decimal(16,15) NULL,
		LATE_DATE smalldatetime NULL,
		LATE_PRINCIPAL money NULL,
		LATE_PERCENT money NULL,
		OVERDUE_DATE smalldatetime NULL,
		OVERDUE_PRINCIPAL money NULL,
		OVERDUE_PRINCIPAL_INTEREST money NULL,
		OVERDUE_PRINCIPAL_INTEREST_DAILY money NULL,
		OVERDUE_PRINCIPAL_INTEREST_FRACTION decimal(16,15) NULL,
		OVERDUE_PRINCIPAL_PENALTY money NULL,
		OVERDUE_PRINCIPAL_PENALTY_DAILY money NULL,
		OVERDUE_PRINCIPAL_PENALTY_FRACTION decimal(16,15) NULL,
		OVERDUE_PERCENT money NULL,
		OVERDUE_PERCENT_PENALTY money NULL,
		OVERDUE_PERCENT_PENALTY_DAILY money NULL,
		OVERDUE_PERCENT_PENALTY_FRACTION decimal(16,15) NULL,
		CALLOFF_PRINCIPAL money NULL,
		CALLOFF_PRINCIPAL_INTEREST money NULL,
		CALLOFF_PRINCIPAL_INTEREST_DAILY money NULL,
		CALLOFF_PRINCIPAL_INTEREST_FRACTION decimal(16,15) NULL,
		CALLOFF_PRINCIPAL_PENALTY money NULL,
		CALLOFF_PRINCIPAL_PENALTY_DAILY money NULL,
		CALLOFF_PRINCIPAL_PENALTY_FRACTION decimal(16,15) NULL,
		CALLOFF_PERCENT money NULL,
		CALLOFF_PERCENT_PENALTY money NULL,
		CALLOFF_PERCENT_PENALTY_DAILY money NULL,
		CALLOFF_PERCENT_PENALTY_FRACTION decimal(16,15) NULL,
		CALLOFF_PENALTY money NULL,
		WRITEOFF_PRINCIPAL money NULL,
		WRITEOFF_PRINCIPAL_PENALTY money NULL,
		WRITEOFF_PRINCIPAL_PENALTY_DAILY money NULL,
		WRITEOFF_PRINCIPAL_PENALTY_FRACTION decimal(16,15) NULL,
		WRITEOFF_PERCENT money NULL,
		WRITEOFF_PERCENT_PENALTY money NULL,
		WRITEOFF_PERCENT_PENALTY_DAILY money NULL,
		WRITEOFF_PERCENT_PENALTY_FRACTION decimal(16,15) NULL,
		WRITEOFF_PENALTY money NULL,
		IMMEDIATE_PENALTY money NULL,
		FINE money NULL,
		MAX_CATEGORY_LEVEL tinyint NULL,
		CATEGORY_1 money NULL,
		CATEGORY_2 money NULL,
		CATEGORY_3 money NULL,
		CATEGORY_4 money NULL,
		CATEGORY_5 money NULL,
		CATEGORY_6 money NULL,
		OVERDUE_INSURANCE money NULL,
		OVERDUE_SERVICE_FEE money NULL,
		DEFERABLE_INTEREST money NULL,
		DEFERABLE_OVERDUE_INTEREST money NULL,
		DEFERABLE_PENALTY money NULL,
		DEFERABLE_FINE money NULL,
		REMAINING_FEE money NULL
		PRIMARY KEY (LOAN_ID))

	CREATE TABLE #tbl_ops(
		OP_ID int IDENTITY(1,1) NOT NULL,
		LOAN_ID int NOT NULL,
		OP_DATE smalldatetime NOT NULL,
		OP_TYPE smallint NOT NULL,
		OP_STATE tinyint NOT NULL,
		OP_TIME datetime NOT NULL,
		PARENT_OP_ID int NULL,
		AMOUNT money NULL,
		BY_PROCESSING bit NOT NULL,
		OP_DATA xml NULL,
		OP_DETAILS xml NULL,
		OP_EXT_XML_1 xml NULL,
		OP_EXT_XML_2 xml NULL,
		OP_LOAN_DETAILS xml NULL,
		OP_NOTE varchar(255) NULL,
		OWNER int NOT NULL,
		DOC_REC_ID int NULL,
		NOTE_REC_ID int NULL,
		UPDATE_DATA bit NOT NULL,
		UPDATE_SCHEDULE bit NOT NULL,
		AUTH_OWNER int NULL
		PRIMARY KEY (OP_ID))
END


CREATE TABLE #tbl_detail_late(
	LOAN_ID int NOT NULL,
	LATE_DATE smalldatetime NOT NULL,
	LATE_OP_ID int NOT NULL,
	LATE_PRINCIPAL money NULL,
	LATE_PERCENT money NULL
	PRIMARY KEY (LOAN_ID, LATE_DATE)
)

CREATE TABLE dbo.#tbl_detail_overdue(
	LOAN_ID int NOT NULL,
	OVERDUE_DATE smalldatetime NOT NULL,
	LATE_OP_ID int NULL,
	OVERDUE_OP_ID int NOT NULL,
	OVERDUE_PRINCIPAL money NULL,
	OVERDUE_PERCENT money NULL
	PRIMARY KEY (LOAN_ID, OVERDUE_DATE)
)

CREATE TABLE #tbl_late(
	LOAN_ID			int NOT NULL,
	LATE_DATE			smalldatetime NOT NULL,
	LATE_OP_ID		int NOT NULL,
	LATE_PRINCIPAL	money NULL,
	LATE_PERCENT		money NULL 
	PRIMARY KEY (LOAN_ID, LATE_DATE)
)

CREATE TABLE #tbl_overdue(
	LOAN_ID			int NOT NULL,
	OVERDUE_DATE		smalldatetime NOT NULL,	
	LATE_OP_ID		int NULL,
	OVERDUE_OP_ID		int NOT NULL,
	OVERDUE_PRINCIPAL int NULL,
	OVERDUE_PERCENT	int NULL 
	PRIMARY KEY (LOAN_ID, OVERDUE_DATE)
)

DECLARE
	@_date smalldatetime,
	@_date2 smalldatetime
DECLARE 
	@r int,
	@e int
DECLARE
	@doc_rec_id int

DECLARE
	@prepay_penalty money
DECLARE --სესხის დეტალები
	@calc_date smalldatetime,
	@prev_step smalldatetime,
	@late_date smalldatetime,
	@overdue_date smalldatetime,
	@calloff_date smalldatetime,
	@writeoff_date smalldatetime,
	@linked_ccy TISO,
	@indexed_rate money,	


	@nu_principal money,
	@nu_principal_ money,
	@nu_principal_payed money,
	@nu_interest money,
	@nu_interest_daily money,
	@nu_interest_fraction decimal(16,15),
	@nu_interest_ money,
	@nu_interest_payed money,
	@principal money,
	@principal_ money,
	@principal_payed money,
	@interest money,
	@interest_daily money,
	@interest_fraction decimal(16,15),
	@interest_ money,
	@interest_payed money,

	@late_principal money,
	@late_principal_ money,
	@late_principal_payed money,	
	@late_percent money,
	@late_percent_ money,
	@late_percent_payed money,
	@overdue_principal money,
	@overdue_principal_ money,
	@overdue_principal_payed money,
	@overdue_principal_interest money,
	@overdue_principal_interest_ money,
	@overdue_principal_interest_payed money,
	@overdue_principal_interest_daily money,
	@overdue_principal_interest_fraction decimal(16,15),
	@overdue_principal_penalty money,
	@overdue_principal_penalty_ money,
	@overdue_principal_penalty_payed money,
	@overdue_principal_penalty_daily money,
	@overdue_principal_penalty_fraction decimal(16,15),     
	@overdue_percent money,
	@overdue_percent_ money,
	@overdue_percent_payed money,
	@overdue_percent_penalty money,
	@overdue_percent_penalty_ money,
	@overdue_percent_penalty_payed money,
	@overdue_percent_penalty_daily money,
	@overdue_percent_penalty_fraction decimal(16,15),
	@calloff_principal money,
	@calloff_principal_ money,
	@calloff_principal_payed money,
	@calloff_principal_interest money,
	@calloff_principal_interest_ money,
	@calloff_principal_interest_payed money,
	@calloff_principal_interest_daily money,
	@calloff_principal_interest_fraction decimal(16,15),
	@calloff_principal_penalty money,
	@calloff_principal_penalty_ money,
	@calloff_principal_penalty_payed money,
	@calloff_principal_penalty_daily money,
	@calloff_principal_penalty_fraction decimal(16,15),
	@calloff_percent money,
	@calloff_percent_ money,
	@calloff_percent_payed money,
	@calloff_percent_penalty money,
	@calloff_percent_penalty_ money,
	@calloff_percent_penalty_payed money,
	@calloff_percent_penalty_daily money,
	@calloff_percent_penalty_fraction decimal(16,15),
	@calloff_penalty money,       
	@calloff_penalty_ money,
	@calloff_penalty_payed money,
	@writeoff_principal money,
	@writeoff_principal_ money,
	@writeoff_principal_payed money,	
	@writeoff_principal_penalty money,
	@writeoff_principal_penalty_ money, 
	@writeoff_principal_penalty_payed money,
	@writeoff_principal_penalty_daily money,
	@writeoff_principal_penalty_fraction decimal(16,15),
	@writeoff_percent money,
	@writeoff_percent_ money,
	@writeoff_percent_payed money,
	@writeoff_percent_penalty money,
	@writeoff_percent_penalty_ money,
	@writeoff_percent_penalty_payed money,
	@writeoff_percent_penalty_daily money,
	@writeoff_percent_penalty_fraction decimal(16,15),
	@writeoff_penalty money,
	@writeoff_penalty_ money,
	@writeoff_penalty_payed money,
	@immediate_penalty money,
	@immediate_penalty_ money,
	@immediate_penalty_payed money,
	@fine money,
	@fine_ money,
	@fine_payed money,

	@max_category_level tinyint,
	@category_1 money,
	@category_2 money,
	@category_3 money,           
	@category_4 money,
	@category_5 money,
	@category_6 money,

	@overdue_insurance money, 
	@overdue_service_fee money,

	@deferable_interest money, 
	@deferable_overdue_interest money, 
	@deferable_penalty money,
	@deferable_fine money




DECLARE
	@schedule_date								smalldatetime,
	@schedule_interest_date						smalldatetime,
	@schedule_principal							money,
	@schedule_interest							money,
	@schedule_nu_interest						money,
	@schedule_balance							money,
	@schedule_pay_interest						bit,
	@schedule_principal_						money,
	@schedule_interest_							money,
	@schedule_nu_interest_						money,
	@schedule_nu_interest_correction			money,
	@schedule_interest_correction				money,
	@schedule_insurance							money,
	@schedule_service_fee						money,


	@schedule_defered_interest					money,
	@schedule_defered_overdue_interest			money,
	@schedule_defered_penalty					money,
	@schedule_defered_fine						money,

	@step_defered_interest						money


DECLARE
	@client_no				int,
	@client_amount			money,
	@client_amount_			money,
	@iso					TISO,
	@end_date				smalldatetime,
	@disburse_type			int,
	@schedule_type			int,
	@interest_flags			int,
	@penalty_flags			int,
	@nu_intrate				money,
	@intrate				money,
	@penalty_intrate		money,
	@penalty_delta			bit,
	@basis					int

DECLARE
	@parent_op_id int,
	@child_op_id int,
	@op_commit bit,
	@late_op_id int
DECLARE
	@step_late_date smalldatetime,
	@step_late_percent money,
	@step_late_principal money
DECLARE
	@step_overdue_date smalldatetime,
	@step_overdue_percent money,
	@step_overdue_principal money,
	@step_overdue_insurance money,
	@step_overdue_service_fee money

DECLARE
	@schedule_control bit,
	@grace_finish_date smalldatetime,
	@guarantee bit


DECLARE
	@op_amount		money,
	@note_rec_id	int,
	@op_data		XML,
	@op_details		XML,
	@op_ext_xml_1	XML,
	@op_ext_xml_2	XML

DECLARE --variables for global SETTINGS
	@l_late_days int -- რამდენი დაგვიანებული დღის შემდეგ გადავიდეს სესხი ვადაგადაცილებაზე, თუ  0, მაშინ დაგვიანების მაგივრად პირდაპირ ვადაგადაცილებაზე გადავა

DECLARE
	@op_count int


EXEC dbo.GET_SETTING_INT 'L_LATE_DAYS', @l_late_days OUTPUT

SET IDENTITY_INSERT #tbl_ops ON
INSERT INTO #tbl_ops(OP_ID,LOAN_ID,OP_DATE,OP_TYPE,OP_STATE,OP_TIME,PARENT_OP_ID,AMOUNT,BY_PROCESSING,OP_DATA,OP_DETAILS,OP_EXT_XML_1,OP_EXT_XML_2,OP_LOAN_DETAILS,OP_NOTE,OWNER,DOC_REC_ID,NOTE_REC_ID,UPDATE_DATA,UPDATE_SCHEDULE,AUTH_OWNER)
SELECT OP_ID,LOAN_ID,OP_DATE,OP_TYPE,OP_STATE,OP_TIME,PARENT_OP_ID,AMOUNT,BY_PROCESSING,OP_DATA,OP_DETAILS,OP_EXT_XML_1,OP_EXT_XML_2,OP_LOAN_DETAILS,OP_NOTE,OWNER,DOC_REC_ID,NOTE_REC_ID,UPDATE_DATA,UPDATE_SCHEDULE,AUTH_OWNER
FROM dbo.LOAN_OPS
WHERE LOAN_ID=@loan_id
SET IDENTITY_INSERT #tbl_ops OFF

INSERT INTO #tbl_details
SELECT * FROM dbo.LOAN_DETAILS
WHERE LOAN_ID=@loan_id

INSERT INTO #tbl_detail_late
SELECT * FROM dbo.LOAN_DETAIL_LATE
WHERE LOAN_ID=@loan_id

INSERT INTO #tbl_detail_overdue
SELECT * FROM dbo.LOAN_DETAIL_OVERDUE
WHERE LOAN_ID=@loan_id

SET @_date2 = @date
SELECT @date = CALC_DATE
FROM #tbl_details

WHILE @date < @_date2
BEGIN
	SET @_date = DATEADD(dd, 1, @date)

	DECLARE cr CURSOR FAST_FORWARD LOCAL FOR
	SELECT L.LOAN_ID, L.CLIENT_NO, L.ISO, L.DISBURSE_TYPE, L.SCHEDULE_TYPE, L.END_DATE, L.INTEREST_FLAGS, L.PENALTY_FLAGS,
		L.NOTUSED_INTRATE, L.INTRATE, L.PENALTY_INTRATE, L.BASIS, L.GRACE_FINISH_DATE, 
		D.CALC_DATE, D.PREV_STEP, ISNULL(D.NU_PRINCIPAL,$0.00), ISNULL(D.NU_INTEREST,$0.00), ISNULL(D.NU_INTEREST_DAILY,$0.00), ISNULL(D.NU_INTEREST_FRACTION,$0.00), ISNULL(D.PRINCIPAL,$0.00), ISNULL(D.INTEREST,$0.00), ISNULL(D.INTEREST_DAILY,$0.00), ISNULL(D.INTEREST_FRACTION,$0.00),
		D.LATE_DATE, ISNULL(D.LATE_PRINCIPAL,$0.00), ISNULL(D.LATE_PERCENT,$0.00),
		D.OVERDUE_DATE, ISNULL(D.OVERDUE_PRINCIPAL,$0.00), ISNULL(D.OVERDUE_PRINCIPAL_INTEREST,$0.00), ISNULL(D.OVERDUE_PRINCIPAL_INTEREST_DAILY,$0.00), ISNULL(D.OVERDUE_PRINCIPAL_INTEREST_FRACTION,$0.00), ISNULL(D.OVERDUE_PRINCIPAL_PENALTY,$0.00), ISNULL(D.OVERDUE_PRINCIPAL_PENALTY_DAILY,$0.00), ISNULL(D.OVERDUE_PRINCIPAL_PENALTY_FRACTION,$0.00),
		ISNULL(D.OVERDUE_PERCENT,$0.00), ISNULL(D.OVERDUE_PERCENT_PENALTY,$0.00), ISNULL(D.OVERDUE_PERCENT_PENALTY_DAILY,$0.00), ISNULL(D.OVERDUE_PERCENT_PENALTY_FRACTION,$0.00),
		L.CALLOFF_DATE, ISNULL(D.CALLOFF_PRINCIPAL,$0.00), ISNULL(D.CALLOFF_PRINCIPAL_INTEREST,$0.00), ISNULL(D.CALLOFF_PRINCIPAL_INTEREST_DAILY,$0.00), ISNULL(D.CALLOFF_PRINCIPAL_INTEREST_FRACTION,$0.00), ISNULL(D.CALLOFF_PRINCIPAL_PENALTY,$0.00), ISNULL(D.CALLOFF_PRINCIPAL_PENALTY_DAILY,$0.00), ISNULL(D.CALLOFF_PRINCIPAL_PENALTY_FRACTION,$0.00),
		ISNULL(D.CALLOFF_PERCENT,$0.00), ISNULL(D.CALLOFF_PERCENT_PENALTY,$0.00), ISNULL(D.CALLOFF_PERCENT_PENALTY_DAILY,$0.00), ISNULL(D.CALLOFF_PERCENT_PENALTY_FRACTION,$0.00), ISNULL(D.CALLOFF_PENALTY,$0.00),
		L.WRITEOFF_DATE, ISNULL(D.WRITEOFF_PRINCIPAL,$0.00), ISNULL(D.WRITEOFF_PRINCIPAL_PENALTY,$0.00), ISNULL(D.WRITEOFF_PRINCIPAL_PENALTY_DAILY,$0.00), ISNULL(D.WRITEOFF_PRINCIPAL_PENALTY_FRACTION,$0.00),
		ISNULL(D.WRITEOFF_PERCENT,$0.00), ISNULL(D.WRITEOFF_PERCENT_PENALTY,$0.00), ISNULL(D.WRITEOFF_PERCENT_PENALTY_DAILY,$0.00), ISNULL(D.WRITEOFF_PERCENT_PENALTY_FRACTION,$0.00), ISNULL(D.WRITEOFF_PENALTY,$0.00),
		ISNULL(D.IMMEDIATE_PENALTY,$0.00), ISNULL(D.FINE,$0.00), ISNULL(D.MAX_CATEGORY_LEVEL, 1),
		ISNULL(D.CATEGORY_1,$0.00), ISNULL(D.CATEGORY_2,$0.00), ISNULL(D.CATEGORY_3,$0.00), ISNULL(D.CATEGORY_4,$0.00), ISNULL(D.CATEGORY_5,$0.00), ISNULL(D.CATEGORY_6,$0.00),
		ISNULL(D.OVERDUE_INSURANCE,$0.00), ISNULL(D.OVERDUE_SERVICE_FEE,$0.00), L.LINKED_CCY, L.INDEXED_RATE,
		ISNULL(D.DEFERABLE_INTEREST, $0.00), ISNULL(D.DEFERABLE_OVERDUE_INTEREST, $0.00), ISNULL(D.DEFERABLE_PENALTY, $0.00), ISNULL(D.DEFERABLE_FINE, $0.00), GUARANTEE
		
	FROM dbo.LOANS L
		INNER JOIN #tbl_details D ON D.LOAN_ID = L.LOAN_ID
	WHERE (L.LOAN_ID = @loan_id) AND (D.CALC_DATE = @date)

	OPEN cr
	FETCH NEXT FROM cr
	INTO @loan_id, @client_no, @iso, @disburse_type, @schedule_type, @end_date, @interest_flags, @penalty_flags,
		@nu_intrate, @intrate, @penalty_intrate, @basis, @grace_finish_date,
		@calc_date, @prev_step, @nu_principal, @nu_interest, @nu_interest_daily, @nu_interest_fraction, @principal, @interest, @interest_daily, @interest_fraction,
		@late_date, @late_principal, @late_percent, 
		@overdue_date, @overdue_principal, @overdue_principal_interest, @overdue_principal_interest_daily, @overdue_principal_interest_fraction, @overdue_principal_penalty, @overdue_principal_penalty_daily, @overdue_principal_penalty_fraction,
		@overdue_percent, @overdue_percent_penalty, @overdue_percent_penalty_daily, @overdue_percent_penalty_fraction,
		@calloff_date, @calloff_principal, @calloff_principal_interest, @calloff_principal_interest_daily, @calloff_principal_interest_fraction, @calloff_principal_penalty, @calloff_principal_penalty_daily, @calloff_principal_penalty_fraction,
		@calloff_percent, @calloff_percent_penalty, @calloff_percent_penalty_daily, @calloff_percent_penalty_fraction, @calloff_penalty,
		@writeoff_date, @writeoff_principal, @writeoff_principal_penalty, @writeoff_principal_penalty_daily, @writeoff_principal_penalty_fraction,
		@writeoff_percent, @writeoff_percent_penalty, @writeoff_percent_penalty_daily, @writeoff_percent_penalty_fraction, @writeoff_penalty,
		@immediate_penalty, @fine, @max_category_level,
		@category_1, @category_2, @category_3, @category_4, @category_5, @category_6,
		@overdue_insurance, @overdue_service_fee, @linked_ccy, @indexed_rate,
		@deferable_interest, @deferable_overdue_interest, @deferable_penalty, @deferable_fine, @guarantee


	WHILE @@FETCH_STATUS = 0
	BEGIN

		SET @op_count = 0
		SET @schedule_date = NULL
		SET @schedule_interest_date = NULL
		SET @schedule_principal = NULL
		SET @schedule_interest = NULL
		SET @schedule_balance = NULL
		SET @schedule_pay_interest = NULL
		SET @schedule_nu_interest_correction = NULL
		SET @schedule_interest_correction = NULL


		SELECT TOP 1 @schedule_date=SCHEDULE_DATE, @schedule_interest_date=INTEREST_DATE, @schedule_principal=PRINCIPAL, @schedule_interest=INTEREST, @schedule_nu_interest=NU_INTEREST, @schedule_balance=BALANCE, @schedule_pay_interest=PAY_INTEREST,
			@schedule_nu_interest_correction = NU_INTEREST_CORRECTION, @schedule_interest_correction = INTEREST_CORRECTION

		FROM dbo.LOAN_SCHEDULE
		WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE >= @date AND ORIGINAL_AMOUNT IS NOT NULL AND (ISNULL(AMOUNT, $0.00) > $0.00 OR @disburse_type = 4) 
		ORDER BY SCHEDULE_DATE

		SELECT TOP 1 @schedule_insurance = INSURANCE, @schedule_service_fee = CASE WHEN @date = SCHEDULE_DATE THEN SERVICE_FEE ELSE $0.00 END,
						@schedule_defered_interest = ISNULL(DEFERED_INTEREST, $0.00), @schedule_defered_overdue_interest = ISNULL(DEFERED_OVERDUE_INTEREST, $0.00),
						@schedule_defered_penalty = ISNULL(DEFERED_PENALTY, $0.00), @schedule_defered_fine = ISNULL(DEFERED_FINE, $0.00)
		FROM dbo.LOAN_SCHEDULE
		WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE >= @date AND ORIGINAL_AMOUNT IS NOT NULL
		ORDER BY SCHEDULE_DATE

		IF @disburse_type = 4
		BEGIN
			IF @schedule_date = @date
			BEGIN
				SET @schedule_principal = @principal - @schedule_balance
				
				IF @schedule_principal < 0
					SET @schedule_principal = $0.00

				IF @schedule_pay_interest = 0 
				BEGIN
					SET @schedule_nu_interest = $0.00
					SET @schedule_interest = $0.00
				END
				ELSE
				BEGIN
					SET @schedule_nu_interest = @nu_interest
					SET @schedule_interest = @interest
				END
			END
			ELSE
			BEGIN
				SET @schedule_principal = $0.00	
				SET @schedule_interest = $0.00
				SET @schedule_nu_interest = $0.00
			END
		END

		DELETE FROM #tbl_late
		INSERT INTO #tbl_late(LOAN_ID,LATE_DATE,LATE_OP_ID,LATE_PRINCIPAL,LATE_PERCENT) 
		SELECT LOAN_ID,LATE_DATE,LATE_OP_ID,LATE_PRINCIPAL,LATE_PERCENT
		FROM #tbl_detail_late (NOLOCK)
		WHERE LOAN_ID = @loan_id

		DELETE FROM #tbl_overdue
		INSERT INTO #tbl_overdue(LOAN_ID,OVERDUE_DATE,LATE_OP_ID,OVERDUE_OP_ID,OVERDUE_PRINCIPAL,OVERDUE_PERCENT)
		SELECT LOAN_ID,OVERDUE_DATE,LATE_OP_ID,OVERDUE_OP_ID,OVERDUE_PRINCIPAL,OVERDUE_PERCENT
		FROM #tbl_detail_overdue (NOLOCK)
		WHERE LOAN_ID = @loan_id


		SET @parent_op_id = NULL
		SET @child_op_id = NULL
		SET @op_commit = 0

		SET @step_late_date = NULL
		SET @step_late_percent = NULL
		SET @step_late_principal = NULL

		SET @step_overdue_date = NULL
		SET @step_overdue_percent = NULL
		SET @step_overdue_principal = NULL


		SET @nu_principal_					= @nu_principal
		SET @nu_interest_					= @nu_interest
		SET @principal_						= @principal
		SET @interest_						= @interest
		SET @late_principal_				= @late_principal
		SET @late_percent_					= @late_percent
		SET @overdue_principal_				= @overdue_principal
		SET @overdue_principal_interest_	= @overdue_principal_interest
		SET @overdue_principal_penalty_		= @overdue_principal_penalty
		SET @overdue_percent_				= @overdue_percent
		SET @overdue_percent_penalty_		= @overdue_percent_penalty
		SET @calloff_principal_				= @calloff_principal
		SET @calloff_principal_interest_	= @calloff_principal_interest
		SET @calloff_principal_penalty_		= @calloff_principal_penalty
		SET @calloff_percent_				= @calloff_percent
		SET @calloff_percent_penalty_		= @calloff_percent_penalty
		SET @calloff_penalty_				= @calloff_penalty
		SET @writeoff_principal_			= @writeoff_principal
		SET @writeoff_principal_penalty_	= @writeoff_principal_penalty
		SET @writeoff_percent_				= @writeoff_percent
		SET @writeoff_percent_penalty_		= @writeoff_percent_penalty
		SET @writeoff_penalty_				= @writeoff_penalty
		SET @immediate_penalty_				= @immediate_penalty
		SET @fine_							= @fine

		SET	@schedule_principal_			= @schedule_principal
		SET	@schedule_interest_				= @schedule_interest
		SET	@schedule_nu_interest_			= @schedule_nu_interest


		/* ვადაგადაცილების დაფიქსირება */														
		EXEC @r = dbo.loan_process_overdue
			@loan_id					= @loan_id,												
			@date						= @date,												
			@op_commit					= @op_commit OUTPUT,									
			@schedule_date				= @schedule_date,										
			@schedule_nu_interest		= @schedule_nu_interest OUTPUT,							
			@schedule_interest			= @schedule_interest OUTPUT,							
			@schedule_principal			= @schedule_principal OUTPUT,							
			@schedule_insurance			= @schedule_insurance OUTPUT,							
			@schedule_service_fee		= @schedule_service_fee OUTPUT,							
			@schedule_defered_interest	= @schedule_defered_interest OUTPUT,					
			@nu_interest				= @nu_interest OUTPUT,									
			@interest					= @interest OUTPUT,										
			@principal					= @principal OUTPUT,									
			@deferable_interest			= @deferable_interest OUTPUT,							
			@overdue_percent			= @overdue_percent OUTPUT,								
			@overdue_principal			= @overdue_principal OUTPUT,							
			@step_overdue_percent		= @step_overdue_percent OUTPUT,							
			@step_overdue_principal		= @step_overdue_principal OUTPUT,						
			@overdue_insurance			= @overdue_insurance OUTPUT,							
			@overdue_service_fee		= @overdue_service_fee OUTPUT,							
			@step_overdue_insurance		= @step_overdue_insurance OUTPUT,						
			@step_overdue_service_fee	= @step_overdue_service_fee OUTPUT,
			@step_defered_interest		= @step_defered_interest OUTPUT,
			@op_details					= @op_details OUTPUT

		SET @e = @@ERROR
		IF @r <> 0 OR @e <> 0 GOTO _ret

		IF @op_commit = 1
		BEGIN
			SET @op_count = @op_count + 1
			SET @op_data=
				(SELECT @step_overdue_percent AS OVERDUE_PERCENT, @step_overdue_principal AS OVERDUE_PRINCIPAL, @step_overdue_insurance AS OVERDUE_INSURANCE, @step_overdue_service_fee AS OVERDUE_SERVICE_FEE, @step_defered_interest AS OVERDUE_DEFERED_INTEREST FOR XML RAW, TYPE)

			SET @op_amount = @step_overdue_percent + @step_overdue_principal
			SET @op_amount = ISNULL(@step_overdue_percent, $0.00) + ISNULL(@step_overdue_principal, $0.00) + ISNULL(@step_overdue_insurance, $0.00) + ISNULL(@step_overdue_service_fee, $0.00) + ISNULL(@step_defered_interest, $0.00)

			INSERT INTO dbo.LOAN_NOTES(LOAN_ID, OWNER, OP_TYPE)
			VALUES(@loan_id, @user_id, dbo.loan_const_op_overdue())
			SELECT @e=@@ERROR, @r=@@ROWCOUNT
			IF @r <> 1 OR @e <> 0 GOTO _ret

			SET @note_rec_id = @@IDENTITY

			INSERT INTO #tbl_ops(LOAN_ID, OP_DATE, OP_TYPE, OP_STATE, OP_TIME, PARENT_OP_ID, AMOUNT, BY_PROCESSING, OP_DATA, OP_DETAILS, OWNER, UPDATE_DATA, UPDATE_SCHEDULE, NOTE_REC_ID)
			VALUES(-1, @date, dbo.loan_const_op_overdue(), 0xFF, getdate(), @parent_op_id, @op_amount, 1, @op_data, @op_details, @user_id, 0, 0, @note_rec_id)
			SELECT @e=@@ERROR, @r=@@ROWCOUNT
			IF @r <> 1 OR @e <> 0 GOTO _ret

			SET @child_op_id = @@IDENTITY

			UPDATE #tbl_overdue
			SET OVERDUE_OP_ID = @child_op_id
			WHERE LOAN_ID = @loan_id AND OVERDUE_OP_ID = -1

			IF @parent_op_id IS NULL
				SET @parent_op_id = @child_op_id

			/*EXEC @r = dbo.LOAN_SP_EXEC_OP
				@doc_rec_id = @doc_rec_id OUTPUT,
				@op_id = @child_op_id,
				@user_id = @user_id,
				@by_processing = 1
			SELECT @e=@@ERROR
			IF @r <> 0 OR @e <> 0 GOTO _ret*/
		END
	_skip_overdue:	

		/* დაგვიანების დაფიქსირება  */ --ÄÓ ÌÄØÀÍÉÆÌÉ ÌÀÉÍÝ ÀÒ ÌÖÛÀÏÁÓ ÀÌÉÔÏÌ ÜÀÅáÓÄÍÉ
--		IF (@l_late_days = 0) GOTO _skip_lating
--
--		EXEC @r = dbo.LOAN_SP_LOAN_PROCESSING_LATE  
--			@loan_id = @loan_id,
--			@date = @date,
--			@op_commit = @op_commit OUTPUT,
--			@schedule_date = @schedule_date,
--			@schedule_nu_interest = @schedule_nu_interest OUTPUT,
--			@schedule_interest = @schedule_interest OUTPUT,
--			@schedule_principal = @schedule_principal OUTPUT,
--			@nu_interest = @nu_interest OUTPUT,
--			@interest = @interest OUTPUT,
--			@principal = @principal OUTPUT,
--			@late_date = @late_date OUTPUT,
--			@late_percent = @late_percent OUTPUT,
--			@late_principal = @late_principal OUTPUT,
--			@step_late_date = @step_late_date OUTPUT,
--			@step_late_percent = @step_late_percent OUTPUT,
--			@step_late_principal = @step_late_principal OUTPUT
--
--
--		SET @e = @@ERROR
--		IF @r <> 0 OR @e <> 0 GOTO _ret
--
--		IF @op_commit = 1
--		BEGIN
--			SET @op_count = @op_count + 1
--			SET @op_data =
--				(SELECT @step_late_percent AS LATE_PERCENT, @step_late_principal AS LATE_PRINCIPAL FOR XML RAW, TYPE)
--
--			SET @op_amount = @step_late_percent + @step_late_principal
--
--			INSERT INTO dbo.LOAN_NOTES(LOAN_ID, OWNER, OP_TYPE)
--			VALUES(@loan_id, @user_id, dbo.loan_const_op_late())
--			SELECT @e=@@ERROR, @r=@@ROWCOUNT
--			IF @r <> 1 OR @e <> 0 GOTO _ret
--
--			SET @note_rec_id = @@IDENTITY		
--
--			INSERT INTO #tbl_ops(LOAN_ID, OP_DATE, OP_TYPE, OP_TIME, OP_STATE, PARENT_OP_ID, AMOUNT, BY_PROCESSING, OP_DATA, OWNER, UPDATE_DATA, UPDATE_SCHEDULE, NOTE_REC_ID)
--			VALUES(-1, @date, dbo.loan_const_op_late(), GETDATE(), 0xFF, @parent_op_id, @op_amount, 1, @op_data, @user_id, 0, 0, @note_rec_id)
--			SELECT @e=@@ERROR, @r=@@ROWCOUNT
--			IF @r <> 1 OR @e <> 0 GOTO _ret
--
--			SET @child_op_id = @@IDENTITY		
--
--			INSERT INTO #tbl_late(LOAN_ID, LATE_DATE, LATE_OP_ID, LATE_PRINCIPAL, LATE_PERCENT)
--			VALUES(@loan_id, @step_late_date, @child_op_id, @step_late_principal, @step_late_percent)
--			SELECT @e=@@ERROR, @r=@@ROWCOUNT
--			IF @r <> 1 OR @e <> 0 GOTO _ret
--
--			IF @parent_op_id IS NULL
--				SET @parent_op_id = @child_op_id
--
--			/*EXEC @r = dbo.LOAN_SP_EXEC_OP
--				@doc_rec_id = @doc_rec_id OUTPUT,
--				@op_id = @child_op_id,
--				@user_id = @user_id,
--				@by_processing = 1
--			SELECT @e=@@ERROR
--			IF @r <> 0 OR @e <> 0 GOTO _ret*/
--		END
	_skip_lating:

		/* დავალიანების დარიცხვა */
		IF (@schedule_date IS NOT NULL) AND (@date = @schedule_date)
		BEGIN
			SET @prev_step = @schedule_date --გადაყენდეს წინა უახლოესი დაფარვის თარიღი გრაფიკის მიხედვით
			SELECT TOP 1 @schedule_date=SCHEDULE_DATE, @schedule_interest_date=INTEREST_DATE, @schedule_principal=PRINCIPAL, @schedule_interest=INTEREST, @schedule_nu_interest=NU_INTEREST, @schedule_balance=BALANCE, @schedule_pay_interest=PAY_INTEREST,
				@schedule_nu_interest_correction = NU_INTEREST_CORRECTION, @schedule_interest_correction = INTEREST_CORRECTION

			FROM dbo.LOAN_SCHEDULE
			WHERE LOAN_ID = @loan_id AND SCHEDULE_DATE > @schedule_date AND ORIGINAL_AMOUNT IS NOT NULL AND (ISNULL(AMOUNT, $0.00)  > $0.00 OR @disburse_type = 4) 
			ORDER BY SCHEDULE_DATE
		END

		IF (@schedule_type = 64) AND (@date = @grace_finish_date) 
		BEGIN
			SELECT 
				@op_amount = SUM(ISNULL(DEFERED_INTEREST, $0.0)) - ISNULL(@deferable_interest, $0.00)
			FROM dbo.LOAN_SCHEDULE
			WHERE LOAN_ID = @loan_id

			INSERT INTO #tbl_ops(LOAN_ID, OP_DATE, OP_TYPE, OP_STATE, OP_TIME, PARENT_OP_ID, AMOUNT, BY_PROCESSING, OP_DATA, OP_DETAILS, OWNER, UPDATE_DATA, UPDATE_SCHEDULE, NOTE_REC_ID)
			VALUES(-1, @date, dbo.loan_const_op_debt_defere(), 0xFF, getdate(), @parent_op_id, @op_amount, 1, @op_data, @op_details, @user_id, 0, 0, NULL)
			SELECT @e=@@ERROR, @r=@@ROWCOUNT
			IF @r <> 1 OR @e <> 0 GOTO _ret

			SET @deferable_interest = @op_amount + ISNULL(@deferable_interest, $0.00)
			SET @interest = $0.00
			SET @prev_step = @date
		END

		SET @schedule_control = CASE WHEN (@schedule_type = 64) AND (@date < @grace_finish_date) THEN 0 ELSE 1 END

		EXEC @r = dbo.loan_get_accrual_amounts
			@loan_id = @loan_id,
			@guarantee = @guarantee,
			@disburse_type = @disburse_type,
			@date = @_date,
			@schedule_control = @schedule_control, -- დარიცხული პროცენტი დაანგარიშდეს გრაფიკის პროცენტიდან  1, თუ დარჩენილი ძირიდან 0
			@schedule_date = @schedule_date,
			@end_date = @end_date,
			@schedule_interest = @schedule_interest,
			@schedule_nu_interest = @schedule_nu_interest,
			@schedule_balance = @schedule_balance,
			@schedule_pay_interest = @schedule_pay_interest,
			@schedule_nu_interest_correction = @schedule_nu_interest_correction,
			@schedule_interest_correction = @schedule_interest_correction,

			@calc_date	= @date,
			@prev_step	= @prev_step,
			@interest_flags = @interest_flags,
			@penalty_flags = @penalty_flags,
			@nu_intrate = @nu_intrate,
			@intrate = @intrate,
			@basis = @basis,
			@penalty_intrate = @penalty_intrate,
			@penalty_delta = @penalty_delta,

			/*ძირითადი თანხები */
			@nu_principal = @nu_principal,
			@principal = @principal,
			@overdue_principal = @overdue_principal,
			@calloff_principal = @calloff_principal,
			@writeoff_principal = @writeoff_principal,

			/*პროცენტები*/
			@overdue_percent = @overdue_percent,
			@calloff_percent = @calloff_percent,
			@writeoff_percent = @writeoff_percent,

			@nu_interest = @nu_interest OUTPUT, 
			@nu_interest_daily = @nu_interest_daily OUTPUT,
			@nu_interest_fraction = @nu_interest_fraction OUTPUT,

			@interest = @interest OUTPUT,
			@interest_daily = @interest_daily OUTPUT,
			@interest_fraction = @interest_fraction OUTPUT, 

			@overdue_principal_interest = @overdue_principal_interest OUTPUT,
			@overdue_principal_interest_daily = @overdue_principal_interest_daily OUTPUT,
			@overdue_principal_interest_fraction = @overdue_principal_interest_fraction OUTPUT,
			@overdue_principal_penalty = @overdue_principal_penalty OUTPUT,
			@overdue_principal_penalty_daily = @overdue_principal_penalty_daily OUTPUT,
			@overdue_principal_penalty_fraction = @overdue_principal_penalty_fraction OUTPUT,
			@overdue_percent_penalty = @overdue_percent_penalty OUTPUT,
			@overdue_percent_penalty_daily = @overdue_percent_penalty_daily OUTPUT,
			@overdue_percent_penalty_fraction = @overdue_percent_penalty_fraction OUTPUT,

			@calloff_principal_interest = @calloff_principal_interest OUTPUT,
			@calloff_principal_interest_daily = @calloff_principal_interest_daily OUTPUT,
			@calloff_principal_interest_fraction = @calloff_principal_interest_fraction OUTPUT,
			@calloff_principal_penalty = @calloff_principal_penalty OUTPUT,
			@calloff_principal_penalty_daily = @calloff_principal_penalty_daily OUTPUT,
			@calloff_principal_penalty_fraction = @calloff_principal_penalty_fraction OUTPUT,
			@calloff_percent_penalty = @calloff_percent_penalty OUTPUT,
			@calloff_percent_penalty_daily = @calloff_percent_penalty_daily OUTPUT,
			@calloff_percent_penalty_fraction = @calloff_percent_penalty_fraction OUTPUT,

			@writeoff_principal_penalty = @writeoff_principal_penalty OUTPUT,
			@writeoff_principal_penalty_daily = @writeoff_principal_penalty_daily OUTPUT,
			@writeoff_principal_penalty_fraction = @writeoff_principal_penalty_fraction OUTPUT,
			@writeoff_percent_penalty = @writeoff_percent_penalty OUTPUT,
			@writeoff_percent_penalty_daily = @writeoff_percent_penalty_daily OUTPUT,	
			@writeoff_percent_penalty_fraction = @writeoff_percent_penalty_fraction OUTPUT	
		/* მონაცემების შეცვლა */

		/* რისკების დადგენა */
		/*IF @writeoff_date IS NULL
		BEGIN
			EXEC @r = dbo.LOAN_SP_LOAN_RISK_ANALYSE
				@loan_id = @loan_id,
				@date = @_date,
				@principal = @principal, 
				@principal_late = @late_principal,
				@principal_overdue = @overdue_principal,
				@calloff_date = @calloff_date,
				@principal_calloff = @calloff_principal,
				@category_1 = @category_1 OUTPUT,
				@category_2 = @category_2 OUTPUT,
				@category_3 = @category_3 OUTPUT,
				@category_4 = @category_4 OUTPUT,
				@category_5 = @category_5 OUTPUT,
				@max_category_level = @max_category_level OUTPUT
			SET @e = @@ERROR
			IF @r <> 0 OR @e <> 0 GOTO _ret
		END*/

		/* დაგვიანების და ვადაგადაცილების თარიღების დადგენა  */
		SET @late_date = NULL
		SET @overdue_date = NULL

		SELECT @late_date = MIN(DL.LATE_DATE)
		FROM #tbl_late DL
			LEFT OUTER JOIN	#tbl_overdue DO ON DL.LATE_OP_ID = DO.LATE_OP_ID
			WHERE (DL.LOAN_ID = @loan_id) AND (DL.LATE_DATE IS NOT NULL) AND
				(ISNULL(DL.LATE_PRINCIPAL, $0.00) + ISNULL(DL.LATE_PERCENT, $0.00) +
				 ISNULL(DO.OVERDUE_PRINCIPAL, $0.00) + ISNULL(DO.OVERDUE_PERCENT, $0.00) <> $0.00) 

		SELECT @overdue_date = MIN(OVERDUE_DATE)
		FROM #tbl_overdue 
		WHERE (LOAN_ID = @loan_id) AND (ISNULL(OVERDUE_PRINCIPAL, $0.00) + ISNULL(OVERDUE_PERCENT, $0.00) <> $0.00) 

		DELETE #tbl_detail_late
		WHERE LOAN_ID = @loan_id
		IF @@ERROR <> 0 GOTO _ret

		INSERT INTO #tbl_detail_late(LOAN_ID,LATE_DATE,LATE_OP_ID,LATE_PRINCIPAL,LATE_PERCENT)
		SELECT LOAN_ID,LATE_DATE,LATE_OP_ID,LATE_PRINCIPAL,LATE_PERCENT
		FROM #tbl_late
		WHERE LOAN_ID = @loan_id
		IF @@ERROR <> 0 GOTO _ret

		DELETE #tbl_detail_overdue
		WHERE LOAN_ID = @loan_id
		IF @@ERROR <> 0 GOTO _ret

		INSERT INTO #tbl_detail_overdue(LOAN_ID,OVERDUE_DATE,LATE_OP_ID,OVERDUE_OP_ID,OVERDUE_PRINCIPAL,OVERDUE_PERCENT)
		SELECT LOAN_ID,OVERDUE_DATE,LATE_OP_ID,OVERDUE_OP_ID,OVERDUE_PRINCIPAL,OVERDUE_PERCENT
		FROM #tbl_overdue
		WHERE LOAN_ID = @loan_id
		IF @@ERROR <> 0 GOTO _ret


		--დეტალების გადატანა არქივში
		/*INSERT INTO dbo.LOAN_DETAILS_HISTORY
		SELECT * FROM dbo.LOAN_DETAILS
		WHERE LOAN_ID = @loan_id*/

		UPDATE #tbl_details
		SET 
			CALC_DATE = @_date,
			PREV_STEP = @prev_step,
			NU_PRINCIPAL = CASE WHEN ISNULL(@nu_principal,$0.00)=$0.00 THEN NULL ELSE @nu_principal END,
			NU_INTEREST = CASE WHEN ISNULL(@nu_interest,$0.00)=$0.00 THEN NULL ELSE @nu_interest END,
			NU_INTEREST_DAILY = CASE WHEN ISNULL(@nu_interest_daily,$0.00)=$0.00 THEN NULL ELSE @nu_interest_daily END,
			NU_INTEREST_FRACTION = CASE WHEN ISNULL(@nu_interest_fraction,$0.00)=$0.00 THEN NULL ELSE @nu_interest_fraction END,
			PRINCIPAL = CASE WHEN ISNULL(@principal,$0.00)=$0.00 THEN NULL ELSE @principal END,
			INTEREST = CASE WHEN ISNULL(@interest,$0.00)=$0.00 THEN NULL ELSE @interest END,
			INTEREST_DAILY = CASE WHEN ISNULL(@interest_daily,$0.00)=$0.00 THEN NULL ELSE @interest_daily END,
			INTEREST_FRACTION = CASE WHEN ISNULL(@interest_fraction,$0.00)=$0.00 THEN NULL ELSE @interest_fraction END,
			LATE_DATE = @late_date,
			LATE_PRINCIPAL = CASE WHEN ISNULL(@late_principal,$0.00)=$0.00 THEN NULL ELSE @late_principal END,
			LATE_PERCENT = CASE WHEN ISNULL(@late_percent,$0.00)=$0.00 THEN NULL ELSE @late_percent END,
			OVERDUE_DATE = @overdue_date,
			OVERDUE_PRINCIPAL = CASE WHEN ISNULL(@overdue_principal,$0.00)=$0.00 THEN NULL ELSE @overdue_principal END,
			OVERDUE_PRINCIPAL_INTEREST = CASE WHEN ISNULL(@overdue_principal_interest,$0.00)=$0.00 THEN NULL ELSE @overdue_principal_interest END,
			OVERDUE_PRINCIPAL_INTEREST_DAILY = CASE WHEN ISNULL(@overdue_principal_interest_daily,$0.00)=$0.00 THEN NULL ELSE @overdue_principal_interest_daily END,
			OVERDUE_PRINCIPAL_INTEREST_FRACTION = CASE WHEN ISNULL(@overdue_principal_interest_fraction,$0.00)=$0.00 THEN NULL ELSE @overdue_principal_interest_fraction END,
			OVERDUE_PRINCIPAL_PENALTY = CASE WHEN ISNULL(@overdue_principal_penalty,$0.00)=$0.00 THEN NULL ELSE @overdue_principal_penalty END,
			OVERDUE_PRINCIPAL_PENALTY_DAILY = CASE WHEN ISNULL(@overdue_principal_penalty_daily,$0.00)=$0.00 THEN NULL ELSE @overdue_principal_penalty_daily END,
			OVERDUE_PRINCIPAL_PENALTY_FRACTION = CASE WHEN ISNULL(@overdue_principal_penalty_fraction,$0.00)=$0.00 THEN NULL ELSE @overdue_principal_penalty_fraction END,
			OVERDUE_PERCENT = CASE WHEN ISNULL(@overdue_percent,$0.00)=$0.00 THEN NULL ELSE @overdue_percent END,
			OVERDUE_PERCENT_PENALTY = CASE WHEN ISNULL(@overdue_percent_penalty,$0.00)=$0.00 THEN NULL ELSE @overdue_percent_penalty END,
			OVERDUE_PERCENT_PENALTY_DAILY = CASE WHEN ISNULL(@overdue_percent_penalty_daily,$0.00)=$0.00 THEN NULL ELSE @overdue_percent_penalty_daily END,
			OVERDUE_PERCENT_PENALTY_FRACTION = CASE WHEN ISNULL(@overdue_percent_penalty_fraction,$0.00)=$0.00 THEN NULL ELSE @overdue_percent_penalty_fraction END,
			CALLOFF_PRINCIPAL = CASE WHEN ISNULL(@calloff_principal,$0.00)=$0.00 THEN NULL ELSE @calloff_principal END,
			CALLOFF_PRINCIPAL_INTEREST = CASE WHEN ISNULL(@calloff_principal_interest,$0.00)=$0.00 THEN NULL ELSE @calloff_principal_interest END,
			CALLOFF_PRINCIPAL_INTEREST_DAILY = CASE WHEN ISNULL(@calloff_principal_interest_daily,$0.00)=$0.00 THEN NULL ELSE @calloff_principal_interest_daily END,
			CALLOFF_PRINCIPAL_INTEREST_FRACTION = CASE WHEN ISNULL(@calloff_principal_interest_fraction,$0.00)=$0.00 THEN NULL ELSE @calloff_principal_interest_fraction END,
			CALLOFF_PRINCIPAL_PENALTY = CASE WHEN ISNULL(@calloff_principal_penalty,$0.00)=$0.00 THEN NULL ELSE @calloff_principal_penalty END,
			CALLOFF_PRINCIPAL_PENALTY_DAILY = CASE WHEN ISNULL(@calloff_principal_penalty_daily,$0.00)=$0.00 THEN NULL ELSE @calloff_principal_penalty_daily END,
			CALLOFF_PRINCIPAL_PENALTY_FRACTION = CASE WHEN ISNULL(@calloff_principal_penalty_fraction,$0.00)=$0.00 THEN NULL ELSE @calloff_principal_penalty_fraction END,
			CALLOFF_PERCENT = CASE WHEN ISNULL(@calloff_percent,$0.00)=$0.00 THEN NULL ELSE @calloff_percent END,
			CALLOFF_PERCENT_PENALTY = CASE WHEN ISNULL(@calloff_percent_penalty,$0.00)=$0.00 THEN NULL ELSE @calloff_percent_penalty END,
			CALLOFF_PERCENT_PENALTY_DAILY = CASE WHEN ISNULL(@calloff_percent_penalty_daily,$0.00)=$0.00 THEN NULL ELSE @calloff_percent_penalty_daily END,
			CALLOFF_PERCENT_PENALTY_FRACTION = CASE WHEN ISNULL(@calloff_percent_penalty_fraction,$0.00)=$0.00 THEN NULL ELSE @calloff_percent_penalty_fraction END,
			CALLOFF_PENALTY = CASE WHEN ISNULL(@calloff_penalty,$0.00)=$0.00 THEN NULL ELSE @calloff_penalty END,
			WRITEOFF_PRINCIPAL = CASE WHEN ISNULL(@writeoff_principal,$0.00)=$0.00 THEN NULL ELSE @writeoff_principal END,
			WRITEOFF_PRINCIPAL_PENALTY = CASE WHEN ISNULL(@writeoff_principal_penalty,$0.00)=$0.00 THEN NULL ELSE @writeoff_principal_penalty END,
			WRITEOFF_PRINCIPAL_PENALTY_DAILY = CASE WHEN ISNULL(@writeoff_principal_penalty_daily,$0.00)=$0.00 THEN NULL ELSE @writeoff_principal_penalty_daily END,
			WRITEOFF_PRINCIPAL_PENALTY_FRACTION = CASE WHEN ISNULL(@writeoff_principal_penalty_fraction,$0.00)=$0.00 THEN NULL ELSE @writeoff_principal_penalty_fraction END,
			WRITEOFF_PERCENT = CASE WHEN ISNULL(@writeoff_percent,$0.00)=$0.00 THEN NULL ELSE @writeoff_percent END,
			WRITEOFF_PERCENT_PENALTY = CASE WHEN ISNULL(@writeoff_percent_penalty,$0.00)=$0.00 THEN NULL ELSE @writeoff_percent_penalty END,
			WRITEOFF_PERCENT_PENALTY_DAILY = CASE WHEN ISNULL(@writeoff_percent_penalty_daily,$0.00)=$0.00 THEN NULL ELSE @writeoff_percent_penalty_daily END,
			WRITEOFF_PERCENT_PENALTY_FRACTION = CASE WHEN ISNULL(@writeoff_percent_penalty_fraction,$0.00)=$0.00 THEN NULL ELSE @writeoff_percent_penalty_fraction END,
			WRITEOFF_PENALTY = CASE WHEN ISNULL(@writeoff_penalty,$0.00)=$0.00 THEN NULL ELSE @writeoff_penalty END,
			IMMEDIATE_PENALTY = CASE WHEN ISNULL(@immediate_penalty,$0.00)=$0.00 THEN NULL ELSE @immediate_penalty END,
			FINE = CASE WHEN ISNULL(@fine,$0.00)=$0.00 THEN NULL ELSE @fine END,
			MAX_CATEGORY_LEVEL = @max_category_level,
			CATEGORY_1 = CASE WHEN ISNULL(@category_1,$0.00)=$0.00 THEN NULL ELSE @category_1 END,
			CATEGORY_2 = CASE WHEN ISNULL(@category_2,$0.00)=$0.00 THEN NULL ELSE @category_2 END,
			CATEGORY_3 = CASE WHEN ISNULL(@category_3,$0.00)=$0.00 THEN NULL ELSE @category_3 END,
			CATEGORY_4 = CASE WHEN ISNULL(@category_4,$0.00)=$0.00 THEN NULL ELSE @category_4 END,
			CATEGORY_5 = CASE WHEN ISNULL(@category_5,$0.00)=$0.00 THEN NULL ELSE @category_5 END,
			CATEGORY_6 = CASE WHEN ISNULL(@category_6,$0.00)=$0.00 THEN NULL ELSE @category_6 END,
			OVERDUE_INSURANCE = CASE WHEN ISNULL(@overdue_insurance,$0.00)=$0.00 THEN NULL ELSE @overdue_insurance END,
			OVERDUE_SERVICE_FEE = CASE WHEN ISNULL(@overdue_service_fee,$0.00)=$0.00 THEN NULL ELSE @overdue_service_fee END,
			DEFERABLE_INTEREST = CASE WHEN ISNULL(@deferable_interest,$0.00)=$0.00 THEN NULL ELSE @deferable_interest END,
			DEFERABLE_OVERDUE_INTEREST = CASE WHEN ISNULL(@deferable_overdue_interest,$0.00)=$0.00 THEN NULL ELSE @deferable_overdue_interest END,
			DEFERABLE_PENALTY = CASE WHEN ISNULL(@deferable_penalty,$0.00)=$0.00 THEN NULL ELSE @deferable_penalty END,
			DEFERABLE_FINE = CASE WHEN ISNULL(@deferable_fine,$0.00)=$0.00 THEN NULL ELSE @deferable_fine END
		WHERE LOAN_ID = @loan_id


	/*	UPDATE dbo.LOANS
		SET STATE = @state, CATEGORY_LEVEL = @category_level 
		WHERE LOAN_ID = @loan_id*/

		IF @op_count > 1
			UPDATE #tbl_ops
			SET PARENT_OP_ID = -1
			WHERE OP_ID = @parent_op_id

		FETCH NEXT FROM cr
		INTO @loan_id, @client_no, @iso, @disburse_type, @schedule_type, @end_date, @interest_flags, @penalty_flags,
			@nu_intrate, @intrate, @penalty_intrate, @basis, @grace_finish_date,
			@calc_date, @prev_step, @nu_principal, @nu_interest, @nu_interest_daily, @nu_interest_fraction, @principal, @interest, @interest_daily, @interest_fraction,  
			@late_date, @late_principal, @late_percent, 
			@overdue_date, @overdue_principal, @overdue_principal_interest, @overdue_principal_interest_daily, @overdue_principal_interest_fraction, @overdue_principal_penalty, @overdue_principal_penalty_daily, @overdue_principal_penalty_fraction,
			@overdue_percent, @overdue_percent_penalty, @overdue_percent_penalty_daily, @overdue_percent_penalty_fraction,
			@calloff_date, @calloff_principal, @calloff_principal_interest, @calloff_principal_interest_daily, @calloff_principal_interest_fraction, @calloff_principal_penalty, @calloff_principal_penalty_daily, @calloff_principal_penalty_fraction,
			@calloff_percent, @calloff_percent_penalty, @calloff_percent_penalty_daily, @calloff_percent_penalty_fraction, @calloff_penalty,
			@writeoff_date, @writeoff_principal, @writeoff_principal_penalty, @writeoff_principal_penalty_daily, @writeoff_principal_penalty_fraction,
			@writeoff_percent, @writeoff_percent_penalty, @writeoff_percent_penalty_daily, @writeoff_percent_penalty_fraction, @writeoff_penalty,
			@immediate_penalty, @fine, @max_category_level,
			@category_1, @category_2, @category_3, @category_4, @category_5, @category_6,
			@overdue_insurance, @overdue_service_fee, @linked_ccy, @indexed_rate,
			@deferable_interest, @deferable_overdue_interest, @deferable_penalty, @deferable_fine, @guarantee
	END

	_ret:
	CLOSE cr
	DEALLOCATE cr

	SET @date = DATEADD(dd, 1, @date)
END
--SELECT * FROM #tbl_details
--SELECT * FROM #tbl_detail_late
--SELECT * FROM #tbl_detail_overdue
--SELECT * FROM #tbl_ops

DROP TABLE #tbl_late
DROP TABLE #tbl_overdue
DROP TABLE #tbl_detail_late
DROP TABLE #tbl_detail_overdue
IF @create_tables = 1
BEGIN
	DROP TABLE #tbl_details
	DROP TABLE #tbl_ops
END
IF @r <> 0 RETURN @r
IF @e <> 0 RETURN @e		
SELECT 'OK' AS RESULT
RETURN 0

GO
