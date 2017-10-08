SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [impexp].[swift_message_builder950]
	@rec_id int,
	@uid int,
	@acc_id int,
	@bic TINTBANKCODE,
	@statement_no int,
	@swift_file_name varchar(128),
	@user_id int
AS
SET NOCOUNT ON
DECLARE
	@swift_msg varchar(max)

DECLARE
	@MsgBegin char(1),
	@MsgEnd char(1),
	@Cr char(1),
	@Lf char(1),
	@CrLf char(2),
	@MsgType char(3),
	@oInputLT varchar(37),
	@SeqNum int

SET @MsgBegin = CHAR(0x1)
SET @MsgEnd = CHAR(0x3)
SET @Cr = CHAR(0xD)
SET @Lf = CHAR(0xA)
SET @CrLf = @Cr + @Lf
SET @MsgType = '950'
SET @SeqNum = 1


DECLARE
	@r int,
	@client_no int,
	@client_code char(2),
	@create_date smalldatetime,
	@swift_start_date smalldatetime,
	@our_bank_code_int TINTBANKCODE,
	@bal_amount money,
	@bal_amount_str varchar(15),
	@bal_type char(1),
	@bal_date smalldatetime,
	@date smalldatetime,
	@dbo money,
	@cro money,
	@doc_num varchar(20),
	@cor_account varchar(20),
	@sw_code char(3),
	@sw_code_descrip varchar(100)


DECLARE
	@ref_num					varchar(32),
	@ccy						char(3),
	@msg_header					varchar(500),
	@msg_footer					varchar(300),
	@saldo						money

EXEC @r = dbo.GET_SETTING_STR 'OUR_BANK_CODE_INT', @our_bank_code_int OUTPUT

SET @ccy = dbo.acc_get_ccy(@acc_id)

SET @oInputLT = CASE WHEN LEN(@bic) = 8 THEN @bic + 'XXXX' ELSE SUBSTRING(@bic, 1, 8) + 'X' + SUBSTRING(@bic, 9, 3) END

SELECT @client_no = CLIENT_NO, @create_date = CREATE_DT, @swift_start_date = SWIFT_START_DATE
FROM impexp.STATEMENTS (NOLOCK)
WHERE REC_ID = @rec_id

SELECT @client_code = CLIENT_CODE
FROM impexp.STATEMENT_CLIENTS (NOLOCK)
WHERE CLIENT_NO = @client_no

SET @ref_num = SUBSTRING(convert(varchar(8), @create_date, 112), 3, 6) + @client_code + '-' + @ccy + REPLICATE('0', 4 - LEN(convert(varchar(4), @statement_no))) + convert(varchar(4), @statement_no)

/*message header*/
SET @msg_header = '{1:F01' + @our_bank_code_int + 'AXXX' + '0000000000' + '}'
SET @msg_header = @msg_header + '{2:I' + @MsgType + @oInputLT + 'N}'
SET @msg_header = @msg_header + '{4:' + @CrLf
SET @msg_header = @msg_header + ':20:' + @ref_num + @CrLf
SET @msg_header = @msg_header + ':25:' + dbo.acc_get_account_ccy(@acc_id) + @CrLf
/*END message header*/

/*message footer*/
SELECT @bal_date = A1.DT, @bal_amount = A1.SALDO
FROM impexp.STATEMENT_DETAILS A1 (NOLOCK)
WHERE A1.SW_REC_ID = @rec_id AND A1.SORT_ID = (SELECT MAX(A2.SORT_ID) FROM impexp.STATEMENT_DETAILS A2 (NOLOCK) WHERE A2.SW_REC_ID = A1.SW_REC_ID)

SET @bal_type = CASE WHEN @bal_amount <= 0.00 THEN 'C' ELSE 'D' END

SET @msg_footer = ':62F:' + @bal_type + SUBSTRING(convert(varchar(8), @bal_date, 112), 3, 6) + @ccy + REPLACE(convert(varchar(15), ABS(@bal_amount)), '.', ',') + @CrLf + '-}'
/*END  message footer*/

--SET @ref_num = 'STBR' + SUBSTRING(convert(varchar(8), @create_date, 112), 3, 6) + @client_code + REPLICATE('0', 3 - LEN(convert(varchar(3), @statement_no))) + convert(varchar(3), @statement_no) + convert(char(1), @SeqNum)

SET @swift_msg = @MsgBegin + @msg_header
--SET @swift_msg = @swift_msg + ':20:' + @ref_num + @CrLf
--SET @swift_msg = @swift_msg + ':25:' + dbo.acc_get_account_ccy(@acc_id) + @CrLf
SET @swift_msg = @swift_msg + ':28C:' + REPLICATE('0', 4 - LEN(convert(varchar(4), @statement_no))) + convert(varchar(4), @statement_no) + '/' + REPLICATE('0', 4 - LEN(convert(varchar(4), @SeqNum))) + convert(varchar(4), @SeqNum) + @CrLf

SET @bal_date = @swift_start_date
SELECT @bal_amount = A1.SALDO
FROM impexp.STATEMENT_DETAILS A1 (NOLOCK)
WHERE A1.SW_REC_ID = @rec_id AND A1.SORT_ID = (SELECT MIN(A2.SORT_ID) FROM impexp.STATEMENT_DETAILS A2 (NOLOCK) WHERE A2.SW_REC_ID = A1.SW_REC_ID)

SET @bal_type = CASE WHEN @bal_amount <= 0.00 THEN 'C' ELSE 'D' END
SET @swift_msg = @swift_msg + ':60F:' + @bal_type + SUBSTRING(convert(varchar(8), @bal_date, 112), 3, 6) + @ccy + REPLACE(convert(varchar(15), ABS(@bal_amount)), '.', ',') + @CrLf

SET @saldo = @bal_amount

DECLARE cc CURSOR FOR
SELECT DT, DBO, CRO, convert(varchar(20), ISNULL(DOC_NUM, 0)), convert(varchar(20), ACCOUNT), SW_CODE, SW_CODE_DESCRIP FROM impexp.STATEMENT_DETAILS (NOLOCK)
WHERE (SW_REC_ID = @rec_id) AND (ACCOUNT IS NOT NULL)
ORDER BY DT, CASE WHEN DBO IS NULL THEN 1 ELSE 0 END, CRO, DBO

OPEN cc

FETCH NEXT FROM cc
INTO @date, @dbo, @cro, @doc_num, @cor_account, @sw_code, @sw_code_descrip

WHILE @@FETCH_STATUS = 0
BEGIN
	IF NOT (LEN(@swift_msg) + 100 < 1800 * @SeqNum)
	BEGIN
		SET @bal_type = CASE WHEN @saldo <= 0.00 THEN 'C' ELSE 'D' END

		SET @swift_msg = @swift_msg + ':62M:' + @bal_type + SUBSTRING(convert(varchar(8), @date, 112), 3, 6) + @ccy + REPLACE(convert(varchar(15), ABS(@saldo)), '.', ',') + @CrLf + '-}$'
		SET @SeqNum = @SeqNum + 1
		SET @swift_msg = @swift_msg + @msg_header
		--SET @ref_num = 'STBR' + SUBSTRING(convert(varchar(8), @create_date, 112), 3, 6) + @client_code + REPLICATE('0', 3 - LEN(convert(varchar(3), @statement_no))) + convert(varchar(3), @statement_no) + convert(char(1), @SeqNum)
		--SET @swift_msg = @swift_msg + ':20:' + @ref_num + @CrLf
		--SET @swift_msg = @swift_msg + ':25:' + dbo.acc_get_account_ccy(@acc_id) + @CrLf
		SET @swift_msg = @swift_msg + ':28C:' + REPLICATE('0', 4 - LEN(convert(varchar(4), @statement_no))) + convert(varchar(4), @statement_no) + '/' + REPLICATE('0', 4 - LEN(convert(varchar(4), @SeqNum))) + convert(varchar(4), @SeqNum) + @CrLf

		SET @swift_msg = @swift_msg + ':60M:' + @bal_type + SUBSTRING(convert(varchar(8), @date, 112), 3, 6) + @ccy + REPLACE(convert(varchar(15), ABS(@saldo)), '.', ',') + @CrLf
	END

	SET @bal_type = CASE WHEN @dbo IS NOT NULL THEN 'D' ELSE 'C' END
	
	IF @dbo IS NOT NULL
	BEGIN
		IF convert(int, @dbo) = @dbo
			SET @bal_amount_str = convert(varchar(15), convert(int, ABS(@dbo))) + ','
		ELSE 
			SET @bal_amount_str = REPLACE(convert(varchar(15), ABS(@dbo)), '.', ',')

		SET @saldo = @saldo + @dbo
	END
	ELSE
	BEGIN
		IF convert(int, @cro) = @cro
			SET @bal_amount_str = convert(varchar(15), convert(int, ABS(@cro))) + ','
		ELSE 
			SET @bal_amount_str = REPLACE(convert(varchar(15), (@cro)), '.', ',')
		SET @saldo = @saldo - @cro
	END

	SET @swift_msg = @swift_msg + ':61:' + SUBSTRING(convert(varchar(8), @date, 112), 3, 6) + SUBSTRING(convert(varchar(8), @date, 112), 5, 4) + @bal_type + SUBSTRING(@ccy, 3, 1) + @bal_amount_str + 'N' + @sw_code + @cor_account + @CrLf +
		@doc_num + '/' + @sw_code_descrip + @CrLf	

	FETCH NEXT FROM cc
	INTO @date, @dbo, @cro, @doc_num, @cor_account, @sw_code, @sw_code_descrip
END

CLOSE cc
DEALLOCATE cc



SET @swift_msg = @swift_msg + @msg_footer + @MsgEnd + @CrLf 

BEGIN TRAN

INSERT INTO impexp.STATEMENT_SWIFTS(STATEMENT_ID, RECEIVER_INSTITUTION, STATEMENT_NO, REF_NUM, SWIFT_FILE_NAME, [OWNER], SWIFT_TEXT)
VALUES(@rec_id, @bic, @statement_no, @ref_num, @swift_file_name, @user_id, @swift_msg)

UPDATE impexp.STATEMENTS
SET [UID] = [UID] + 1,
	[STATE] = 10
WHERE REC_ID = @rec_id
IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END 

IF NOT EXISTS(SELECT * FROM impexp.STATEMENT_NUMBERING (NOLOCK) WHERE CLIENT_NO = @client_no AND RECEIVER_INSTITUTION = @bic AND ACC_ID = @acc_id)
	INSERT INTO impexp.STATEMENT_NUMBERING(CLIENT_NO, RECEIVER_INSTITUTION, ACC_ID, STATEMENT_NO)
	VALUES (@client_no, @bic, @acc_id, @statement_no)
ELSE
	UPDATE impexp.STATEMENT_NUMBERING
	SET STATEMENT_NO = @statement_no
	WHERE CLIENT_NO = @client_no AND RECEIVER_INSTITUTION = @bic AND ACC_ID = @acc_id
IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END 

COMMIT

SELECT * FROM impexp.V_STATEMENTS
WHERE REC_ID = @rec_id

RETURN (0)
GO
