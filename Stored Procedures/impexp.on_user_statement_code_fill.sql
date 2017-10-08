SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[on_user_statement_code_fill]
	@rec_id int,
	@is_arc bit,
	@doc_type smallint,
	@cor_acc_id int
AS
SET NOCOUNT ON

DECLARE
	@sw_code char(3),
	@sw_code_descrip varchar(100)

IF (@doc_type BETWEEN 100 AND 119)
BEGIN
	SET @sw_code = 'TRF'
	SET @sw_code_descrip = 'TRANSFER'
END

IF (@doc_type BETWEEN 120 AND 129)
BEGIN
	SET @sw_code = 'COL'
	SET @sw_code_descrip = 'COLLECTION'
END

IF (@doc_type BETWEEN 130 AND 149)
BEGIN
	SET @sw_code = 'MSC'
	SET @sw_code_descrip = 'CASH WITHDRAWAL'
END

IF (@doc_type IN (12, 18))
BEGIN
	SET @sw_code = 'CHG'
	SET @sw_code_descrip = 'CHARGE'
END

IF (@doc_type IN (14, 20))
BEGIN
	SET @sw_code = 'FEX'
	SET @sw_code_descrip = 'FOREIGN EXCHANGE'
END

SELECT @sw_code AS SW_CODE, @sw_code_descrip AS SW_CODE_DESCRIP
GO
