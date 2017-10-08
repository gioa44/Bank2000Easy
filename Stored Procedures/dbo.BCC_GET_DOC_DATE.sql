SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[BCC_GET_DOC_DATE] (@bc_login_id int, @doc_date smalldatetime OUTPUT, @changed bit OUTPUT) AS

SET NOCOUNT ON

DECLARE 
  @deadline smalldatetime,
  @today smalldatetime,
  @type tinyint

SET @today = convert(smalldatetime,floor(convert(real,getdate())))

EXEC dbo.BCC_GET_DATE_TYPE @today, @type OUTPUT

SELECT @deadline = CASE WHEN @type = 1 THEN DEADLINE2 ELSE DEADLINE END
FROM dbo.BC_LOGINS
WHERE BC_LOGIN_ID = @bc_login_id

IF @doc_date = @today AND NOT @deadline IS NULL AND
       ((GetDate() - @today) > (@deadline - convert(smalldatetime,floor(convert(real,@deadline)))))
BEGIN
  SET @doc_date = @doc_date + 1
  SET @changed = 1
END

SET @type = 2
WHILE @type = 2
BEGIN
  EXEC dbo.BCC_GET_DATE_TYPE @doc_date, @type OUTPUT
  IF @type = 2
  BEGIN
    SET @doc_date = @doc_date + 1
    SET @changed = 1
  END
END
RETURN (0)

GO
