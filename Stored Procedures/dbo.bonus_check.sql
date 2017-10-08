SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[bonus_check]
	@product_id int,
	@id int,
	@date smalldatetime,
	@client_no int
AS

SET NOCOUNT ON;
	
DECLARE
	@rec_id int, 
	@descrip varchar(100),
	@comments varchar(max),
	@sp_name varchar(128),
	@sql nvarchar(1000),
	@is_valid bit

DECLARE @tbl TABLE (REC_ID int NOT NULL, DESCRIP varchar(100) NOT NULL, COMMENTS text NULL)

DECLARE cc CURSOR FOR
SELECT A.REC_ID, A.DESCRIP, A.COMMENTS, A.SP_NAME
FROM dbo.BONUSES A
WHERE A.BONUS_PRODUCT_ID = @product_id AND @date >= [START_DATE] AND ([END_DATE] IS NULL OR [END_DATE] >= @date)
	AND NOT EXISTS(SELECT * FROM dbo.CLIENT_BONUSES C WHERE C.CLIENT_NO = @client_no AND C.ID = @id)

OPEN cc
FETCH NEXT FROM cc INTO @rec_id, @descrip, @comments, @sp_name

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @sql = N'EXEC ' + @sp_name + N' @product_id, @id, @date, @client_no, @is_valid OUTPUT'

	SET @is_valid = 0
	EXEC sp_executesql @sql, N'@product_id int, @id int, @date smalldatetime, @client_no int, @is_valid bit OUTPUT', @product_id, @id, @date, @client_no, @is_valid OUTPUT

	IF @is_valid = 1
		INSERT INTO @tbl VALUES (@rec_id, @descrip, @comments)

	FETCH NEXT FROM cc INTO @rec_id, @descrip, @comments, @sp_name
END

CLOSE cc
DEALLOCATE cc

SELECT * FROM @tbl
GO
