SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[acc_can_auto_open_account] (@branch_id int, @account TACCOUNT, @iso TISO)
RETURNS bit
AS
BEGIN
	DECLARE 
		@can_auto_open_account bit,
		@template_branch_id int,
		@gel bit

	SET @can_auto_open_account = 0
	
	SELECT @template_branch_id  = VALS 
	FROM dbo.INI_INT (NOLOCK) 
	WHERE IDS = 'AUTO_ACC_TEMPL_BR'

	IF @template_branch_id IS NULL
		SET @template_branch_id = 0
	IF @template_branch_id = @branch_id RETURN @can_auto_open_account
		
	IF @iso = 'GEL'
		SET @gel = 1
	ELSE
		SET @gel = 0

	IF EXISTS(SELECT * FROM dbo.AUTO_OPEN_ACCOUNTS A(NOLOCK) WHERE ACCOUNT = @account AND GEL = @gel)
		SET @can_auto_open_account = 1
	ELSE
		SET @can_auto_open_account = 0
	RETURN @can_auto_open_account
END
GO
