SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_get_depo_bal_acc]
	@bal_acc TBAL_ACC OUTPUT,
	@client_no int,
	@prod_id int,
	@iso TISO,
	@depo_type tinyint
AS
SET NOCOUNT ON;

DECLARE
	@client_type tinyint,
	@client_subtype tinyint,
	@is_resident bit

SELECT @client_type = CLIENT_TYPE, @client_subtype = CLIENT_SUBTYPE, @is_resident = IS_RESIDENT 
FROM dbo.CLIENTS (NOLOCK)
WHERE CLIENT_NO = @client_no

IF @client_type = 5 --ÁÀÍÊÉ
BEGIN
	IF @is_resident = 0
	BEGIN
		IF @iso = 'GEL'
			SET @bal_acc = 1722
		ELSE
			SET @bal_acc = 1732
	END
	BEGIN
		IF @iso = 'GEL'
			SET @bal_acc = 1723
		ELSE
			SET @bal_acc = 1733
	END

	RETURN 0
END
ELSE
IF @client_type = 2
BEGIN
	IF @iso = 'GEL'
	BEGIN
		SET @bal_acc = 3350 + @client_subtype
	END 
	ELSE
	BEGIN
		SET @bal_acc = 3360 + @client_subtype
	END
END
ELSE
IF @client_type = 3
BEGIN
	IF @iso = 'GEL'
	BEGIN
		SET @bal_acc = 3450 + @client_subtype
	END 
	ELSE
	BEGIN
		SET @bal_acc = 3460 + @client_subtype
	END
END
ELSE
IF @client_type IN (1, 4)
BEGIN
	SET @bal_acc = 3650
	IF @iso <> 'GEL'
		SET @bal_acc = @bal_acc + 10

	IF @client_type = 1
		SET @bal_acc = @bal_acc + 1
	ELSE
		SET @bal_acc = @bal_acc + @client_subtype
END

EXEC dbo.on_user_depo_sp_get_depo_bal_acc
	@bal_acc = @bal_acc OUTPUT,
	@client_no = @client_no,
	@prod_id = @prod_id,
	@iso = @iso,
	@depo_type = @depo_type

IF @@ERROR <> 0 RETURN 1;

RETURN 0
GO
