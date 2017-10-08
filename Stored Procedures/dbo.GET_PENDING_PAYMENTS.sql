SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[GET_PENDING_PAYMENTS]
	@delay datetime,
	@try_count int = 100
AS

DECLARE
	@rec_id int,
	@sort_order int,
	@server_state int

	EXEC dbo.GET_SETTING_INT 'SERVER_STATE', @server_state OUTPUT

	IF @server_state = 1
		RETURN 0

	SELECT TOP 1 @rec_id = DOC_REC_ID, @sort_order = SORT_ORDER 
	FROM dbo.PENDING_PAYMENTS
	WHERE REC_STATE = 1 AND WAITING_FLAG = 0 AND LOCK_FLAG = 0 AND SORT_ORDER <= @try_count AND DT_TM <= @delay AND PAUSED = 0 
	ORDER BY SORT_ORDER

	IF @rec_id IS NOT NULL
	BEGIN
		UPDATE dbo.PENDING_PAYMENTS
		SET SORT_ORDER = @sort_order + 1
		WHERE DOC_REC_ID = @rec_id

		SELECT * 
		FROM dbo.PENDING_PAYMENTS 
		WHERE DOC_REC_ID = @rec_id
	END
GO
