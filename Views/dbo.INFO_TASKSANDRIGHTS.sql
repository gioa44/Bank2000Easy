SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[INFO_TASKSANDRIGHTS]
AS
SELECT TASKS.CATEGORY as [ÊÀÔÄÂÏÒÉÀ], TASKS.TASK_ID AS [##], TASKS.DESCRIP AS [ÀÌÏÝÀÍÀ], 
    TASK_RIGHTS.DESCRIP AS [Ö×ËÄÁÀ]
FROM TASKS INNER JOIN
    TASK_RIGHTS ON TASKS.TASK_ID = TASK_RIGHTS.TASK_ID




GO
