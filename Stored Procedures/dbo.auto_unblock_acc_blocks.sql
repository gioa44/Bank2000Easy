SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[auto_unblock_acc_blocks] (@dt smalldatetime) AS

SET NOCOUNT ON;

DECLARE 
	@acc_id int, 
	@block_id int,
	@doc_rec_id int

DECLARE cc CURSOR LOCAL
FOR

SELECT ACC_ID, BLOCK_ID, DOC_REC_ID
FROM dbo.ACCOUNTS_BLOCKS 
WHERE AUTO_UNBLOCK_DATE <= @dt AND IS_ACTIVE = 1

OPEN cc

FETCH NEXT FROM cc INTO @acc_id, @block_id, @doc_rec_id

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC dbo.acc_unblock_amount_by_id @acc_id, @block_id, 2, @doc_rec_id

	FETCH NEXT FROM cc INTO @acc_id, @block_id, @doc_rec_id
END

CLOSE cc
DEALLOCATE cc

DELETE FROM dbo.ACCOUNTS_BLOCKS
WHERE IS_ACTIVE = 0 AND UNBLOCK_DATE_TIME < DATEADD(mm, -1, @dt)
--test
GO
