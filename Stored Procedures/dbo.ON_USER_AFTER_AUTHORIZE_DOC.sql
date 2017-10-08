SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ON_USER_AFTER_AUTHORIZE_DOC]
	@doc_rec_id int,
	@user_id int,
	@new_rec_state tinyint,
	@old_rec_state tinyint
AS

RETURN 0
GO
