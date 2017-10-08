SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_RESTORE_OP_LOAN_COLLATERALS_XML2]
	@op_id int,
	@credit_line_id int
AS

DECLARE
	@r int

SET @r = 0

DELETE FROM dbo.LOAN_CREDIT_LINE_COLLATERALS_LINK WHERE CREDIT_LINE_ID = @credit_line_id --ßÀÅÛÀËÄ ÀÌÀÆÄ ÌÏÁÌÖËÄÁÉ
IF @@ERROR <> 0 BEGIN SET @r =1 GOTO proc_end END

DECLARE @TEMP_LINK1 TABLE(LOAN_ID int, COLLATERAL_ID int)
DECLARE @TEMP_LINK2 TABLE(CREDIT_LINE_ID int, COLLATERAL_ID int)

INSERT INTO dbo.LOAN_CREDIT_LINE_COLLATERALS_LINK (CREDIT_LINE_ID, COLLATERAL_ID)
SELECT @credit_line_id, COLLATERAL_ID FROM dbo.LOAN_VW_OP_LOAN_COLLATERALS2 WHERE OP_ID = @op_id AND IS_LINKED = 1
												
DELETE dbo.LOAN_COLLATERALS_LINK OUTPUT DELETED.LOAN_ID, DELETED.COLLATERAL_ID INTO @TEMP_LINK1 
WHERE COLLATERAL_ID IN (SELECT COLLATERAL_ID FROM dbo.LOAN_VW_OP_LOAN_COLLATERALS2 WHERE OP_ID = @op_id AND ISNULL(IS_LINKED, 0) = 0)

DELETE dbo.LOAN_CREDIT_LINE_COLLATERALS_LINK OUTPUT DELETED.CREDIT_LINE_ID, DELETED.COLLATERAL_ID INTO @TEMP_LINK2 
WHERE COLLATERAL_ID IN (SELECT COLLATERAL_ID FROM dbo.LOAN_VW_OP_LOAN_COLLATERALS2 WHERE OP_ID = @op_id AND ISNULL(IS_LINKED, 0) = 0)

DELETE FROM dbo.LOAN_COLLATERALS WHERE CREDIT_LINE_ID = @credit_line_id
IF @@ERROR <> 0 BEGIN SET @r =1 GOTO proc_end END

DECLARE cr CURSOR FAST_FORWARD LOCAL FOR
SELECT COLLATERAL_ID, MAIN, IS_LINKED FROM dbo.LOAN_VW_OP_LOAN_COLLATERALS2 (NOLOCK)
WHERE OP_ID = @op_id --AND ISNULL(IS_LINKED, 0) = 0

DECLARE
	@collateral_id int,
	@new_collateral_id int,
	@is_linked bit,
	@main bit,
	@main_collateral_list varchar(200)

SET @main_collateral_list = ''

SELECT * INTO #PRE_SAVED_COLLATERALS
FROM dbo.LOAN_VW_OP_LOAN_COLLATERALS2 WHERE CREDIT_LINE_ID = @credit_line_id

OPEN cr
FETCH NEXT FROM cr INTO @collateral_id, @main, @is_linked


WHILE @@FETCH_STATUS = 0
BEGIN
	IF ISNULL(@is_linked, 0) = 1
	BEGIN
		IF @main = 1
			SET @main_collateral_list = @main_collateral_list + CONVERT(varchar(200), @collateral_id) + ','
	END
	ELSE
	BEGIN
		INSERT INTO dbo.LOAN_COLLATERALS (ROW_VERSION, LOAN_ID, CREDIT_LINE_ID, CLIENT_NO, OWNER, ISO, COLLATERAL_TYPE, AMOUNT, DESCRIP, MARKET_AMOUNT, COLLATERAL_DETAILS, IS_ENSURED, ENSURANCE_PAYMENT_AMOUNT, ENSUR_PAYMENT_INTERVAL_TYPE, ENSURANCE_COMPANY_ID)
		SELECT 0 AS ROW_VERSION, LOAN_ID, CREDIT_LINE_ID, CLIENT_NO, OWNER, ISO, COLLATERAL_TYPE, AMOUNT, DESCRIP, MARKET_AMOUNT, XML_STR, IS_ENSURED, ENSURANCE_PAYMENT_AMOUNT, ENSUR_PAYMENT_INTERVAL_TYPE, ENSURANCE_COMPANY_ID FROM dbo.LOAN_VW_OP_LOAN_COLLATERALS2
		WHERE OP_ID = @op_id AND COLLATERAL_ID = @collateral_id
		IF @@ERROR <> 0 BEGIN SET @r =1 GOTO proc_end END

		SET @new_collateral_id = SCOPE_IDENTITY()

		IF @main = 1
			SET @main_collateral_list = @main_collateral_list + CONVERT(varchar(200), @new_collateral_id) + ','

		UPDATE @TEMP_LINK1 SET COLLATERAL_ID = @new_collateral_id WHERE COLLATERAL_ID = @collateral_id
		UPDATE @TEMP_LINK2 SET COLLATERAL_ID = @new_collateral_id WHERE COLLATERAL_ID = @collateral_id

		UPDATE #PRE_SAVED_COLLATERALS SET COLLATERAL_ID = @new_collateral_id WHERE COLLATERAL_ID = @collateral_id
		UPDATE dbo.LOAN_GEN_AGREE_OP_COLLATERALS SET COLLATERAL_ID = @new_collateral_id WHERE OP_ID = @op_id AND COLLATERAL_ID = @collateral_id
	END

	FETCH NEXT FROM cr INTO @collateral_id, @main, @is_linked
END


CLOSE cr
DEALLOCATE cr


DECLARE
	@pre_saved_op_ext_xml_1 xml,
	@pre_saved_op_id int
	

DECLARE cr2 CURSOR FAST_FORWARD LOCAL FOR
SELECT OP_ID FROM dbo.LOAN_GEN_AGREE_OPS (NOLOCK)
WHERE CREDIT_LINE_ID = @credit_line_id AND OP_TYPE IN (dbo.loan_const_gen_agree_op_restruct_collat(), dbo.loan_const_gen_agree_op_correct_collat())

OPEN cr2
FETCH NEXT FROM cr2 INTO @pre_saved_op_id

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @pre_saved_op_ext_xml_1 = (SELECT * FROM #PRE_SAVED_COLLATERALS WHERE OP_ID = @pre_saved_op_id FOR XML RAW, ROOT)

	UPDATE dbo.LOAN_GEN_AGREE_OPS
	SET 
		OP_EXT_XML = @pre_saved_op_ext_xml_1
	WHERE OP_ID = @pre_saved_op_id

	FETCH NEXT FROM cr2 INTO @pre_saved_op_id
END


CLOSE cr2
DEALLOCATE cr2


IF @main_collateral_list = ''
	SET @main_collateral_list = NULL

UPDATE dbo.LOAN_CREDIT_LINES
SET 
	MAIN_COLLATERAL_LIST = @main_collateral_list
WHERE CREDIT_LINE_ID = @credit_line_id
IF @@ERROR <> 0 BEGIN SET @r =1 GOTO proc_end END


INSERT INTO dbo.LOAN_COLLATERALS_LINK SELECT * FROM @TEMP_LINK1
INSERT INTO dbo.LOAN_CREDIT_LINE_COLLATERALS_LINK SELECT * FROM @TEMP_LINK2

proc_end:

DROP TABLE #PRE_SAVED_COLLATERALS

IF @r <> 0
	RAISERROR ('ÛÄÝÃÏÌÀ.',16,1)
	
RETURN @r

GO