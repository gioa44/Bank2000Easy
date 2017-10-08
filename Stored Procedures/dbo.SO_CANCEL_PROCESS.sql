SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[SO_CANCEL_PROCESS]
	@task_id int,
	@user_id int,
	@date smalldatetime,
	@reason varchar(4000),
	@suspended_by_bank bit
AS

DECLARE 
	@state int,
	@doc_rec_id int,
	@task_doc_rec_id int,
	@r int

UPDATE dbo.SO_SCHEDULES 
	SET @state = [STATE],
		@task_doc_rec_id = DOC_REC_ID,
		[STATE] = 0,
		DOC_REC_ID = NULL
WHERE TASK_ID = @task_id AND [DATE] = @date

IF @@ERROR <> 0
BEGIN
	RAISERROR('<ERR>ÅÄÒ áÄÒáÃÄÁÀ ÃÀÅÀËÄÁÉÓ ÂÒÀ×ÉÊÉÓ ÂÀÖØÌÄÁÀ!</ERR>', 16, 1)
	RETURN 1
END

INSERT INTO dbo.SO_SCHEDULE_CHANGES	(TASK_ID, [DATE], [USER_ID], FIELD, OLD_VALUE, NEW_VALUE, OLD_DISPLAY_VALUE, NEW_DISPLAY_VALUE)
	VALUES (@task_id, @date, @user_id, 'STATE', @state, 0, CASE WHEN @state = 10 THEN 'ÂÀÓÀÀØÔÉÖÒÄÁÄËÉ' WHEN @state = 20 THEN 'ÀØÔÉÖÒÉ' WHEN @state = 30 THEN 'ÃÀÄËÏÃÏÓ ÌÏØÌÄÃÄÁÀÓ' WHEN @state = 40 THEN 'ÃÀÓÒÖËÄÁÖËÉ ßÀÒÖÌÀÔÄÁËÀÃ' END, 'ÂÀÖØÌÄÁÖËÉ ' + '(ÌÉÆÄÆÉ: ' + @reason + ')')

IF @@ERROR<>0 
BEGIN
	RAISERROR('<ERR>ÅÄÒ ÌÏáÄÒáÃÀ ÝÅËÉËÄÁÉÓ ËÏÂÉÒÄÁÀ!</ERR>', 16, 1)
	RETURN 1
END
	
IF (@task_doc_rec_id IS NOT NULL)
BEGIN
	DECLARE tran_cr CURSOR LOCAL FAST_FORWARD FOR

	SELECT o.REC_ID
	FROM OPS_0000 (NOLOCK) o
	WHERE RELATION_ID = @task_doc_rec_id OR REC_ID = @task_doc_rec_id
	OPEN tran_cr

	FETCH NEXT FROM tran_cr
	INTO @doc_rec_id
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC @r = dbo.DELETE_DOC 
			@rec_id = @doc_rec_id,
			@user_id = @user_id,
			@check_saldo = 1,
			@dont_check_up = 0,
			@check_limits = 0,
			@info = 0,
			@lat = 0

		IF @r <> 0 
		BEGIN
			CLOSE tran_cr
			DEALLOCATE tran_cr
			
			RETURN 2
		END
		
		FETCH NEXT FROM tran_cr
		INTO @doc_rec_id
	END
	
	CLOSE tran_cr
	DEALLOCATE tran_cr
END
  
SELECT * FROM dbo.SO_PROCESS_VIEW (NOLOCK)
WHERE (TASK_ID = @task_id AND [DATE] = @date)
GO
