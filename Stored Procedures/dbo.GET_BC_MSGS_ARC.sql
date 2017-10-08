SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[GET_BC_MSGS_ARC]
  @st_date smalldatetime = Null,
  @end_date smalldatetime  = Null,
  @bc_client_id int = Null,
  @bc_msg_type int = Null,
  @branch_id int = 0
AS

SET NOCOUNT ON

SELECT M.*, L.DESCRIP AS BC_DESCRIP, C.DESCRIP AS BC_CLIENT_DESCRIP, C.BC_CLIENT_ID, C.MAIN_CLIENT_ID
FROM dbo.BC_MSGS_ARC M (NOLOCK)
    INNER JOIN dbo.BC_LOGINS L(NOLOCK) ON L.BC_LOGIN_ID=M.BC_LOGIN_ID
    INNER JOIN dbo.BC_CLIENTS C (NOLOCK) ON C.BC_CLIENT_ID=L.BC_CLIENT_ID
WHERE
  (@branch_id = 0 OR C.BRANCH_ID = @branch_id) and
  ((@st_date IS NULL) or (DOC_DATE >= @st_date)) and
  ((@end_date IS NULL) or (DOC_DATE <= @end_date)) and
  ((@bc_client_id IS NULL) or (L.BC_CLIENT_ID = @bc_client_id)) and
  ((@bc_msg_type IS NULL) or (MSG_TYPE = @bc_msg_type))
GO
