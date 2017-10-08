SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[ops_get_extra_info] (@op_id int, @acc_id int, @doc_type smallint, @is_debit bit, @is_arc bit)
RETURNS varchar(100)
AS
BEGIN
	DECLARE @extra_info varchar(100)
	SET @extra_info = NULL

	IF @doc_type BETWEEN 10 AND 99
	BEGIN
		SELECT @extra_info = dbo.acc_get_acc_type_name (@acc_id, 0) 
	END
	ELSE
	IF @doc_type BETWEEN 100 AND 109 AND @is_debit <> 0
	BEGIN
		IF @is_arc = 0
			SELECT @extra_info = RECEIVER_ACC_NAME 
			FROM dbo.DOC_DETAILS_PLAT DD (NOLOCK)
			WHERE DD.DOC_REC_ID = @op_id
		ELSE
			SELECT @extra_info = RECEIVER_ACC_NAME 
			FROM dbo.DOC_DETAILS_ARC_PLAT DD (NOLOCK)
			WHERE DD.DOC_REC_ID = @op_id
	END
	ELSE
	IF @doc_type BETWEEN 100 AND 109 AND @is_debit = 0
	BEGIN
		IF @is_arc = 0
			SELECT @extra_info = SENDER_ACC_NAME 
			FROM dbo.DOC_DETAILS_PLAT DD (NOLOCK)
			WHERE DD.DOC_REC_ID = @op_id
		ELSE
			SELECT @extra_info = SENDER_ACC_NAME 
			FROM dbo.DOC_DETAILS_ARC_PLAT DD (NOLOCK)
			WHERE DD.DOC_REC_ID = @op_id
	END
	ELSE
	IF @doc_type BETWEEN 110 AND 119 AND @is_debit <> 0
	BEGIN
		IF @is_arc = 0
			SELECT @extra_info = RECEIVER_ACC_NAME 
			FROM dbo.DOC_DETAILS_VALPLAT DD (NOLOCK)
			WHERE DD.DOC_REC_ID = @op_id
		ELSE
			SELECT @extra_info = RECEIVER_ACC_NAME 
			FROM dbo.DOC_DETAILS_ARC_VALPLAT DD (NOLOCK)
			WHERE DD.DOC_REC_ID = @op_id
	END
	ELSE
	IF @doc_type BETWEEN 110 AND 119 AND @is_debit = 0
	BEGIN
		IF @is_arc = 0
			SELECT @extra_info = SENDER_ACC_NAME 
			FROM dbo.DOC_DETAILS_VALPLAT DD (NOLOCK)
			WHERE DD.DOC_REC_ID = @op_id
		ELSE
			SELECT @extra_info = SENDER_ACC_NAME 
			FROM dbo.DOC_DETAILS_ARC_VALPLAT DD (NOLOCK)
			WHERE DD.DOC_REC_ID = @op_id
	END
	ELSE
	IF @doc_type BETWEEN 120 AND 159
	BEGIN
		IF @is_arc = 0
			SELECT @extra_info = LTRIM(ISNULL(FIRST_NAME,'') + ' ' + ISNULL(LAST_NAME,'')) 
			FROM dbo.DOC_DETAILS_PASSPORTS DD (NOLOCK)
			WHERE DD.DOC_REC_ID = @op_id
		ELSE
			SELECT @extra_info = LTRIM(ISNULL(FIRST_NAME,'') + ' ' + ISNULL(LAST_NAME,'')) 
			FROM dbo.DOC_DETAILS_ARC_PASSPORTS DD (NOLOCK)
			WHERE DD.DOC_REC_ID = @op_id
	END

	RETURN @extra_info
END
GO
