SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[user_smart_card_register]
	@user_id int,
	@client_no int,
	@serial_no varchar(100)
AS

SET NOCOUNT ON;

IF ISNULL(@serial_no, '') = ''
BEGIN
	RAISERROR ('Invalid serial number', 16, 1)
	RETURN 1
END 

DECLARE @smart_card_no varchar(100)

SELECT @smart_card_no = SMART_CARD_NO
FROM dbo.CLIENTS (NOLOCK)
WHERE CLIENT_NO = @client_no

IF @serial_no <> ISNULL(@smart_card_no, '')
BEGIN
	RAISERROR ('Invalid serial number', 16, 1)
	RETURN 2
END

DECLARE 
	@client_no_str varchar(10),
	@old_group_id int,
	@id int

SET @client_no_str = CONVERT(varchar(10), @client_no)

-- Create New Group

SELECT @old_group_id = GROUP_ID, @id = SAVED_GROUP_ID
FROM dbo.USERS
WHERE [USER_ID] = @user_id

IF @old_group_id < 0 -- Has temp group
BEGIN
	EXEC dbo.user_smart_card_unregister @user_id

	SET @old_group_id = @id
END

SET @id = -1000 - @user_id

BEGIN TRAN

SET IDENTITY_INSERT dbo.GROUPS ON

INSERT INTO dbo.GROUPS (GROUP_ID, ACCESS_STRING, ACCESS_STRING_2, DESCRIP)
SELECT @id, G.ACCESS_STRING, G.ACCESS_STRING_2, 'ÃÒÏÄÁÉÈÉ ãÂÖ×É- ÊËÉÄÍÔÉ: ' + @client_no_str + ', ÌÏÌáÌ.: ' + CONVERT(varchar(10), @user_id)
FROM dbo.GROUPS G
	INNER JOIN dbo.USERS U ON U.GROUP_ID = G.GROUP_ID
WHERE U.[USER_ID] = @user_id

SET IDENTITY_INSERT dbo.GROUPS OFF


-- Create Client Set 
SET IDENTITY_INSERT dbo.CLI_SETS ON

INSERT INTO dbo.CLI_SETS (SET_ID, DESCRIP, JOIN_SQL, WHERE_SQL, IS_EXCEPTION)
VALUES (@id, 'ÃÒÏÄÁÉÈÉ ÓÉÌÒÀÅËÄ ÊËÉÄÍÔÉ: ' + @client_no_str , NULL, 'C.CLIENT_NO = ' + @client_no_str, 0)

SET IDENTITY_INSERT dbo.CLI_SETS OFF

INSERT INTO dbo.CLI_SET_RIGHTS (SR.GROUP_ID, SR.SET_ID, SR.RIGHT_NAME)
SELECT DISTINCT @id, @id, SR.RIGHT_NAME
FROM dbo.CLI_SET_RIGHTS SR
	INNER JOIN dbo.CLI_SETS A ON A.SET_ID = SR.SET_ID
WHERE SR.GROUP_ID = @old_group_id AND A.IS_EXCEPTION = 0


-- Create Acc Set 
SET IDENTITY_INSERT dbo.ACC_SETS ON

INSERT INTO dbo.ACC_SETS (SET_ID, DESCRIP, JOIN_SQL, WHERE_SQL, IS_EXCEPTION)
VALUES (@id, 'ÃÒÏÄÁÉÈÉ ÓÉÌÒÀÅËÄ ÊËÉÄÍÔÉ: ' + @client_no_str , NULL, 'A.CLIENT_NO = ' + @client_no_str, 0)

SET IDENTITY_INSERT dbo.ACC_SETS OFF

INSERT INTO dbo.ACC_SET_RIGHTS (SR.GROUP_ID, SR.SET_ID, SR.RIGHT_NAME)
SELECT DISTINCT @id, @id, SR.RIGHT_NAME
FROM dbo.ACC_SET_RIGHTS SR
	INNER JOIN dbo.ACC_SETS A ON A.SET_ID = SR.SET_ID
WHERE SR.GROUP_ID = @old_group_id AND A.IS_EXCEPTION = 0

INSERT INTO dbo.ACC_SET_RIGHTS (GROUP_ID, SET_ID, RIGHT_NAME)
SELECT @id, SR.SET_ID, SR.RIGHT_NAME
FROM dbo.ACC_SET_RIGHTS SR
	INNER JOIN dbo.ACC_SET_RIGHT_NAMES AN ON AN.RIGHT_NAME = SR.RIGHT_NAME
WHERE SR.GROUP_ID = @old_group_id AND AN.CATEGORY = 'ÏÐÄÒÀÝÉÄÁÉ'


-- Create Ops Set 
SET IDENTITY_INSERT dbo.OPS_SETS ON

INSERT INTO dbo.OPS_SETS (SET_ID, DESCRIP, JOIN_SQL, WHERE_SQL, IS_EXCEPTION)
VALUES (@id, 'ÃÒÏÄÁÉÈÉ ÓÉÌÒÀÅËÄ ÊËÉÄÍÔÉ: ' + @client_no_str ,  
	'INNER JOIN dbo.ACCOUNTS A1 (NOLOCK) ON A1.ACC_ID=O.DEBIT_ID INNER JOIN dbo.ACCOUNTS A2 (NOLOCK) ON A2.ACC_ID=O.CREDIT_ID',
    '(A1.CLIENT_NO=' + @client_no_str +' OR A2.CLIENT_NO=' + @client_no_str + ')', 0)

SET IDENTITY_INSERT dbo.OPS_SETS OFF

INSERT INTO dbo.OPS_SET_RIGHTS (SR.GROUP_ID, SR.SET_ID, SR.RIGHT_NAME)
SELECT DISTINCT @id, @id, SR.RIGHT_NAME
FROM dbo.OPS_SET_RIGHTS SR
	INNER JOIN dbo.OPS_SETS A ON A.SET_ID = SR.SET_ID
WHERE SR.GROUP_ID = @old_group_id AND A.IS_EXCEPTION = 0


UPDATE dbo.USERS
SET GROUP_ID = @id, SAVED_GROUP_ID = @old_group_id
WHERE [USER_ID] = @user_id

COMMIT
GO
