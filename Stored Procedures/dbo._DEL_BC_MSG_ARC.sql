SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[_DEL_BC_MSG_ARC] @rec_id int AS

DELETE FROM dbo.BC_MSGS_ARC
WHERE REC_ID = @rec_id
GO
