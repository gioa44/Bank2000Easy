SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[acc_get_balance] (
  @acc_id int, 
  @date smalldatetime, 
  @start_balance bit = 0, 
  @equ bit = 0,
  @shadow_level smallint = -1
)
RETURNS money AS
BEGIN
	IF @start_balance <> 0
		SET @date = @date - 1

	DECLARE 
		@tmp_date smalldatetime,
		@balance money

	SET @tmp_date = dbo.bank_first_date ()

	IF @date < @tmp_date RETURN $0.0000

	SET @tmp_date = dbo.bank_open_date()
	IF @date >= @tmp_date
	BEGIN
		SELECT @balance = A.SALDO
		FROM dbo.ACCOUNTS_DETAILS A (NOLOCK)
		WHERE A.ACC_ID = @acc_id

		SET @balance = ISNULL(@balance, $0.0000)

		IF @shadow_level >= 0
		BEGIN
			DECLARE
				@rec_state 	smallint,
				@a money

			IF @shadow_level <= 0
				SET @rec_state = 0
			ELSE
			IF @shadow_level = 1
				SET @rec_state = 10
			ELSE
			IF @shadow_level >= 2
				SET @rec_state = 20

			SELECT @a = SUM(CASE @acc_id WHEN D.DEBIT_ID THEN D.AMOUNT ELSE $0 END) - SUM(CASE @acc_id WHEN D.CREDIT_ID THEN D.AMOUNT ELSE $0 END)
			FROM dbo.OPS_HELPER_0000 S(NOLOCK) 
				INNER JOIN dbo.OPS_0000 D(NOLOCK) ON D.REC_ID = S.REC_ID
			WHERE S.ACC_ID = @acc_id AND S.DT <= @date AND D.REC_STATE >= @rec_state
		
			SET @balance = @balance + ISNULL(@a, $0.0000)
		END
	END
	ELSE
	BEGIN
		DECLARE	@dt_first_day_of_year smalldatetime
		SET @dt_first_day_of_year = dbo.first_day_of_year(@date)

		SELECT @balance = A.SALDO
		FROM dbo.SALDOS A (NOLOCK)
		WHERE A.ACC_ID = @acc_id AND A.DT =
			(SELECT MAX(B.DT) FROM dbo.SALDOS B (NOLOCK) WHERE B.ACC_ID = A.ACC_ID AND B.DT BETWEEN @dt_first_day_of_year AND @date)
	END

	IF @equ <> 0 AND @balance <> $0.0000
		SET @balance = dbo.get_equ(@balance, dbo.acc_get_ccy(@acc_id), @date)

	RETURN ISNULL(@balance, $0.00)
END
GO
