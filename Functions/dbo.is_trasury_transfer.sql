SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[is_trasury_transfer] (@bank_code TGEOBANKCODE, @receiver_acc TINTACCOUNT) 
RETURNS bit
AS
BEGIN
	DECLARE 
		@result bit,
		@tr_bank_code TGEOBANKCODE,
		@tr_account TINTACCOUNT

	SET @result = 0

	SELECT @tr_bank_code = VALS FROM dbo.INI_INT WHERE IDS = 'XAZINA_BANK_CODE'
	SELECT @tr_account = VALS FROM dbo.INI_INT WHERE IDS = 'XAZINA_ACCOUNT'

	IF @tr_bank_code IS NULL
		SET @tr_bank_code = 220101107
	IF @tr_account IS NULL
		SET @tr_account = 200122900

	IF (@bank_code = @tr_bank_code) AND (@receiver_acc = @tr_account)
	  SET @result = 1

	RETURN @result
END
GO
