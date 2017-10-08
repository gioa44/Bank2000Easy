SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [impexp].[on_user_review_doc_state_in_swift] 
	@row_id int, 
	@acc_state int,
	@acc_type int,
	@acc_subtype int,
	@doc_state int OUTPUT, -- InputOutput
	@other_info varchar(max) OUTPUT, -- InputOutput
	@error_reason varchar(max) OUTPUT -- InputOutput
AS

SET NOCOUNT ON;

GO
